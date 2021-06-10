--# selene: allow(shadowing)

-- https://github.com/OpenPrograms/LibCompress/blob/master/LibCompress.lua

local type = type
local select = select
local next = next
local setmetatable = setmetatable
local table_insert = table.insert
local table_remove = table.remove
local table_concat = table.concat
local string_char = string.char
local string_byte = string.byte
local string_len = string.len
local string_sub = string.sub
local pairs = pairs
local bit_band = bit32.band
local bit_bor = bit32.bor
local bit_lshift = bit32.lshift
local bit_rshift = bit32.rshift

local tables = {} -- tables that may be cleaned have to be kept here
local tables_to_clean = {} -- list of tables by name (string) that may be reset to {} after a timeout

local function setCleanupTables(...)
	for i=1,select("#",...) do
		tables_to_clean[(select(i, ...))] = true
	end
end

local function addCode(tree, bcode,len)
	if tree then
		tree.bcode = bcode;
		tree.blength = len;
		if tree.c1 then
			addCode(tree.c1, bit_bor(bcode, bit_lshift(1,len)), len+1)
		end
		if tree.c2 then
			addCode(tree.c2, bcode, len+1)
		end
	end
end

local function escape_code(code, len)
	local escaped_code = 0;
	local b;
	local l = 0;
	for i = len-1, 0,- 1 do
		b = bit_band( code, bit_lshift(1,i))==0 and 0 or 1
		escaped_code = bit_lshift(escaped_code,1+b) + b
		l = l + b;
	end
	return escaped_code, len+l
end

tables.Huffman_compressed = {}
tables.Huffman_large_compressed = {}

local compressed_size = 0
local remainder;
local remainder_length;
local function addBits(tbl, code, len)
	remainder = remainder + bit_lshift(code, remainder_length)
	remainder_length = len + remainder_length
	if remainder_length > 32 then
		return true -- Bits lost due to too long code-words.
	end
	while remainder_length>=8 do
		compressed_size = compressed_size + 1
		tbl[compressed_size] = string_char(bit_band(remainder, 255))
		remainder = bit_rshift(remainder, 8)
		remainder_length = remainder_length -8
	end
end

-- word size for this huffman algorithm is 8 bits (1 byte). This means the best compression is representing 1 byte with 1 bit, i.e. compress to 0.125 of original size.
function compress(uncompressed)
	if not type(uncompressed)=="string" then
		return nil, "Can only compress strings"
	end
	if #uncompressed == 0 then
		return "\001"
	end

	-- make histogram
	local hist = {}
	local n = 0
	-- dont have to use all datat to make the histogram
	local uncompressed_size = string_len(uncompressed)
	local c;
	for i = 1, uncompressed_size do
		c = string_byte(uncompressed, i)
		hist[c] = (hist[c] or 0) + 1
	end

	--Start with as many leaves as there are symbols.
	local leafs = {}
	local leaf;
	local symbols = {}
	for symbol, weight in pairs(hist) do
		leaf = { symbol=string_char(symbol), weight=weight };
		symbols[symbol] = leaf;
		table_insert(leafs, leaf)
	end
	--Enqueue all leaf nodes into the first queue (by probability in increasing order so that the least likely item is in the head of the queue).
	table.sort(leafs, function(a,b)
    if a.weight < b.weight then
        return true
    elseif a.weight > b.weight then
        return false else
            return nil
        end
    end)

	local nLeafs = #leafs

	-- create tree
	local huff = {}
	--While there is more than one node in the queues:
	local l,h, li, hi, leaf1, leaf2
	local newNode;
	while #leafs+#huff > 1 do
		-- Dequeue the two nodes with the lowest weight.
		-- Dequeue first
		if not next(huff) then
			li, leaf1 = next(leafs)
			table_remove(leafs, li)
		elseif not next(leafs) then
			hi, leaf1 = next(huff)
			table_remove(huff, hi)
		else
			li, l = next(leafs);
			hi, h = next(huff);
			if l.weight<=h.weight then
				leaf1 = l;
				table_remove(leafs, li)
			else
				leaf1 = h;
				table_remove(huff, hi)
			end
		end
		-- Dequeue second
		if not next(huff) then
			li, leaf2 = next(leafs)
			table_remove(leafs, li)
		elseif not next(leafs) then
			hi, leaf2 = next(huff)
			table_remove(huff, hi)
		else
			li, l = next(leafs);
			hi, h = next(huff);
			if l.weight<=h.weight then
				leaf2 = l;
				table_remove(leafs, li)
			else
				leaf2 = h;
				table_remove(huff, hi)
			end
		end

		--Create a new internal node, with the two just-removed nodes as children (either node can be either child) and the sum of their weights as the new weight.
		newNode = { c1 = leaf1, c2 = leaf2, weight = leaf1.weight+leaf2.weight }
		table_insert(huff,newNode)
	end
	if #leafs>0 then
		li, l = next(leafs)
		table_insert(huff, l)
		table_remove(leafs, li)
	end
	huff = huff[1];

	-- assign codes to each symbol
	-- c1 = "0", c2 = "1"
	-- As a common convention, bit '0' represents following the left child and bit '1' represents following the right child.
	-- c1 = left, c2 = right

	addCode(huff,0,0);
	if huff then
		huff.bcode = 0
		huff.blength = 1
	end

	-- READING
	-- bitfield = 0
	-- bitfield_len = 0
	-- read byte1
	-- bitfield = bitfield + bit_lshift(byte1, bitfield_len)
	-- bitfield_len = bitfield_len + 8
	-- read byte2
	-- bitfield = bitfield + bit_lshift(byte2, bitfield_len)
	-- bitfield_len = bitfield_len + 8
	-- (use 5 bits)
	--	word = bit_band( bitfield, bit_lshift(1,5)-1)
	--	bitfield = bit_rshift( bitfield, 5)
	--	bitfield_len = bitfield_len - 5
	-- read byte3
	-- bitfield = bitfield + bit_lshift(byte3, bitfield_len)
	-- bitfield_len = bitfield_len + 8

	-- WRITING
	remainder = 0;
	remainder_length = 0;

	local compressed = tables.Huffman_compressed
	--compressed_size = 0

	-- first byte is version info. 0 = uncompressed, 1 = 8-bit word huffman compressed
	compressed[1] = "\003"

	-- Header: byte 0=#leafs, byte 1-3=size of uncompressed data
	-- max 2^24 bytes
	local l = string_len(uncompressed)
	compressed[2] = string_char(bit_band(nLeafs-1, 255))			-- number of leafs
	compressed[3] = string_char(bit_band(l, 255))			-- bit 0-7
	compressed[4] = string_char(bit_band(bit_rshift(l, 8), 255))	-- bit 8-15
	compressed[5] = string_char(bit_band(bit_rshift(l, 16), 255))	-- bit 16-23
	compressed_size = 5

	-- create symbol/code map
	for symbol, leaf in pairs(symbols) do
		addBits(compressed, symbol, 8);
		if addBits(compressed, escape_code(leaf.bcode, leaf.blength)) then
			-- code word too long. Needs new revision to be able to handle more than 32 bits
			return string_char(0)..uncompressed
		end
		addBits(compressed, 3, 2);
	end

	-- create huffman code
	local large_compressed = tables.Huffman_large_compressed
	local large_compressed_size = 0
	local ulimit
	for i = 1, l, 200 do
		ulimit = l<(i+199) and l or (i+199)
		for sub_i = i, ulimit do
			c = string_byte(uncompressed, sub_i)
			addBits(compressed, symbols[c].bcode, symbols[c].blength)
		end
		large_compressed_size = large_compressed_size + 1
		large_compressed[large_compressed_size] = table_concat(compressed, "", 1, compressed_size)
		compressed_size = 0
	end

	-- add remainding bits (if any)
	if remainder_length>0 then
		large_compressed_size = large_compressed_size + 1
		large_compressed[large_compressed_size] = string_char(remainder)
	end
	local compressed_string = table_concat(large_compressed, "", 1, large_compressed_size)

	-- is compression worth it? If not, return uncompressed data.
	if (#uncompressed+1) <= #compressed_string then
		return "\001"..uncompressed
	end

	setCleanupTables("Huffman_compressed", "Huffman_large_compressed")
	return compressed_string
end

-- lookuptable (cached between calls)
local lshiftMask = {}
setmetatable(lshiftMask, {
	__index = function (t, k)
		local v = bit_lshift(1, k)
		rawset(t, k, v)
		return v
	end
})

-- lookuptable (cached between calls)
local lshiftMinusOneMask = {}
setmetatable(lshiftMinusOneMask, {
	__index = function (t, k)
		local v = bit_lshift(1, k)-1
		rawset(t, k, v)
		return v
	end
})

local function getCode(bitfield, field_len)
	if field_len>=2 then
		local b;
		local p = 0;
		for i = 0, field_len-1 do
			b = bit_band(bitfield, lshiftMask[i])
			if not (p==0) and not (b == 0) then
				-- found 2 bits set right after each other (stop bits)
				return bit_band( bitfield, lshiftMinusOneMask[i-1]), i-1, bit_rshift(bitfield, i+1), field_len-i-1
			end
			p = b
		end
	end
	return nil
end

local function unescape_code(code, code_len)
	local unescaped_code=0;
	local b;
	local l = 0;
	local i = 0
	while i < code_len do
		b = bit_band( code, lshiftMask[i])
		if not (b==0) then
			unescaped_code = bit_bor(unescaped_code, lshiftMask[l])
			i = i + 1
		end
		i = i + 1
		l = l + 1
	end
	return unescaped_code, l
end

tables.Huffman_uncompressed = {}
tables.Huffman_large_uncompressed = {} -- will always be as big as the larges string ever decompressed. Bad, but clearing i every timetakes precious time.

function decompress(compressed)
	local uncompressed = tables.Huffman_uncompressed
	local large_uncompressed = tables.Huffman_large_uncompressed

	if not type(uncompressed)=="string" then
		return nil, "Can only uncompress strings"
	end

	local compressed_size = #compressed
	--decode header
	local info_byte = string_byte(compressed)
	-- is data compressed
	if info_byte==1 then
		return compressed:sub(2) --return uncompressed data
	end
	if not (info_byte==3) then
		return nil, "Can only decompress Huffman compressed data ("..tostring(info_byte)..")"
	end

	local num_symbols = string_byte(string_sub(compressed, 2, 2)) + 1
	local c0 = string_byte(string_sub(compressed, 3, 3))
	local c1 = string_byte(string_sub(compressed, 4, 4))
	local c2 = string_byte(string_sub(compressed, 5, 5))
	local orig_size = c2*65536 + c1*256 + c0
	if orig_size==0 then
		return "";
	end

	-- decode code->symbal map
	local bitfield = 0;
	local bitfield_len = 0;
	local map = {} -- only table not reused in Huffman decode.
	setmetatable(map, {
		__index = function (t, k)
			local v = {}
			rawset(t, k, v)
			return v
		end
	})

	local i = 6; -- byte 1-5 are header bytes
	local c, cl;
	local minCodeLen = 1000;
	local maxCodeLen = 0;
	local symbol, code, code_len, _bitfield, _bitfield_len;
	local n = 0;
	local state = 0; -- 0 = get symbol (8 bits),  1 = get code (varying bits, ends with 2 bits set)
	while n<num_symbols do
		if i>compressed_size then
			return nil, "Cannot decode map"
		end

		c = string_byte(compressed, i)
		bitfield = bit_bor(bitfield, bit_lshift(c, bitfield_len))
		bitfield_len = bitfield_len + 8

		if state == 0 then
			symbol = bit_band(bitfield, 255)
			bitfield = bit_rshift(bitfield, 8)
			bitfield_len = bitfield_len -8
			state = 1 -- search for code now
		else
			code, code_len, _bitfield, _bitfield_len = getCode(bitfield, bitfield_len)
			if code then
				bitfield, bitfield_len = _bitfield, _bitfield_len
				c, cl = unescape_code(code, code_len)
				map[cl][c]=string_char(symbol)
				minCodeLen = cl<minCodeLen and cl or minCodeLen
				maxCodeLen = cl>maxCodeLen and cl or maxCodeLen
				--print("symbol: "..string_char(symbol).."  code: "..tobinary(c, cl))
				n = n + 1
				state = 0 -- search for next symbol (if any)
			end
		end
		i=i+1
	end

	-- dont create new subtables for entries not in the map. Waste of space.
	-- But do return an empty table to prevent runtime errors. (instead of returning nil)
	local mt = {}
	setmetatable(map, {
		__index = function()
			return mt
		end
	})

	local uncompressed_size = 0
	local large_uncompressed_size = 0
	local test_code
	local test_code_len = minCodeLen;
	local symbol;
	local dec_size = 0;
	compressed_size = compressed_size + 1
	local temp_limit = 200; -- first limit of uncompressed data. large_uncompressed will hold strings of length 200
	temp_limit = temp_limit > orig_size and orig_size or temp_limit
	while true do
		if test_code_len<=bitfield_len then 
			test_code=bit_band( bitfield, lshiftMinusOneMask[test_code_len])
			symbol = map[test_code_len][test_code]
			if symbol then
				uncompressed_size = uncompressed_size + 1
				uncompressed[uncompressed_size]=symbol
				dec_size = dec_size + 1
				if dec_size >= temp_limit then
					if dec_size>=orig_size then -- checked here for speed reasons
						break;
					end
					-- process compressed bytes in smaller chunks
					large_uncompressed_size = large_uncompressed_size + 1
					large_uncompressed[large_uncompressed_size] = table_concat(uncompressed, "", 1, uncompressed_size)
					uncompressed_size = 0
					temp_limit = temp_limit + 200 -- repeated chunk size is 200 uncompressed bytes
					temp_limit = temp_limit > orig_size and orig_size or temp_limit
				end
				bitfield = bit_rshift(bitfield, test_code_len)
				bitfield_len = bitfield_len - test_code_len
				test_code_len = minCodeLen
			else
				test_code_len = test_code_len + 1
				if test_code_len>maxCodeLen then
					return nil, "Decompression error at "..tostring(i).."/"..tostring(#compressed)
				end
			end
		else
			c = string_byte(compressed, i)
			bitfield = bitfield + bit_lshift(c or 0, bitfield_len)
			bitfield_len = bitfield_len + 8
			if i > compressed_size then
				break;
			end
			i = i + 1
		end
	end

	setCleanupTables("Huffman_uncompressed", "Huffman_large_uncompressed")
	return table_concat(large_uncompressed, "", 1, large_uncompressed_size)..table_concat(uncompressed, "", 1, uncompressed_size)
end

return {
	compress = compress,
	decompress = decompress,
}