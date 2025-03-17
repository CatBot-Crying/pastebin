local src = function()
-- Set Your Libname here
local libNameSo = "libil2cpp.so"  -- Define the library name
local info = gg.getTargetInfo() -- Get information about the target app
local APK = info.label    -- Get APK name

-- Define tables and flags for memory handling
X_X = {}  -- Store memory range start addresses
UwU = 0    -- Counter for memory ranges
LibraryStatus = 0  -- Flag for library status (0 = not found)
MemoryRanges = gg.getRangesList()  -- Get the memory ranges list

-- Check if no memory ranges are found, exit if true
if #MemoryRanges == 0 then
    print("No libraries found. Check environment.")
    gg.setVisible(true)
    os.exit()
end

-- Try to fetch memory ranges for the specified library
MemoryRanges = gg.getRangesList(libNameSo)
if #MemoryRanges == 0 then
    LibraryStatus = 2  -- Mark as split library search
    goto LIBRARY_SPLIT  -- Jump to the split library check
end

-- Loop through memory ranges to find valid range (state == "Xa")
for i, range in ipairs(MemoryRanges) do
    if range.state == "Xa" then
        UwU = UwU + 1
        X_X[UwU] = range.start  -- Store the start address of valid range
        LibrarySize = range["end"] - range.start  -- Get library size
        LibraryStatus = 1  -- Mark library as found
    end
end

-- Check if no valid library was found
if LibraryStatus == 0 then
    print(libNameSo .. " not found in Xa region.")
    gg.setVisible(true)
    os.exit()
end

-- Split library detection and handling
::LIBRARY_SPLIT::
if LibraryStatus == 2 then
    SplitApkFound = false  -- Flag for split APK detection
    MemoryRanges = gg.getRangesList()  -- Get all memory ranges again

    -- Check for "split_config" in the memory range names
    for i, range in ipairs(MemoryRanges) do
        if range.state == "Xa" and string.match(range.name, "split_config") then
            SplitApkFound = true
        end
    end

    -- Handle split APK if found
    if SplitApkFound then
        SplitSizes = {}
        SplitCount = 0
        for i, range in ipairs(MemoryRanges) do
            if range.state == "Xa" then
                SplitCount = SplitCount + 1
                SplitSizes[SplitCount] = range["end"] - range.start  -- Store size of each split
            end
        end

        -- Find the largest split
        if SplitCount > 0 then
            MaxSplitSize = math.max(table.unpack(SplitSizes))
            -- Iterate to find the largest split size
            for i, range in ipairs(MemoryRanges) do
                if range.state == "Xa" and (range["end"] - range.start) == MaxSplitSize then
                    UwU = UwU + 1
                    X_X[UwU] = range.start  -- Store start address of largest split
                    LibrarySize = range["end"] - range.start
                    LibraryStatus = 1
                end
            end
        end
    else
        print("No split_config lib found.")
        gg.setVisible(true)
        os.exit()
    end
end

-- Final library check
if LibraryStatus ~= 1 then
    print("Correct lib not found.")
    gg.setVisible(true)
    os.exit()
end

-- Arm Patch
-- Table to store original values for specific offsets
local Original = {}

-- Function to record the original values at a specific offset range
local function RecordOriginalValue(offset)
    local REV = gg.getValues((function(R)
        for _, x in ipairs({offset}) do -- Set Offset 
            for i = 0, 16, 4 do
                R[#R + 1] = {address = X_X[UwU] + x + i, flags = 4}
            end
        end
        return R
    end)({}))

    -- Store the original values in the Original table using the same offset key
    Original[offset] = REV
end

-- Function to revert the values back to the original state for a specific offset
local function RevertValue(offset)
    local originalValues = Original[offset]
    if originalValues then
        gg.setValues(originalValues)  -- Revert to the original values
        gg.toast("Hack [OFF]")
        gg.sleep(1000)
        gg.toast("--( X_X )--")
    else
        gg.alert("⛔ ERROR : ORIGINAL VALUE NOT FOUND ⛔")
    end
end

-- Inject assembly values
local function injectAssembly(offset, value)
    local addr = X_X[UwU] + offset
    if value == true then
        gg.setValues({
            {address = addr, flags = 4, value = "h200080D2"}, -- MOV X0, #0x1
            {address = addr + 0x4, flags = 4, value = "hC0035FD6"} -- RET
        })
    elseif value == false then
        gg.setValues({
            {address = addr, flags = 4, value = "h000080D2"}, -- MOV X0, #0x0
            {address = addr + 0x4, flags = 4, value = "hC0035FD6"} -- RET
        })
    elseif value <= 0xFFFF then
        gg.setValues({
            {address = addr, flags = 4, value = string.format("~A8 MOV W0, #%d", value)},
            {address = addr + 0x4, flags = 4, value = "~A8 RET"}
        })
    else
        gg.setValues({
            {address = addr, flags = 4, value = string.format("~A8 MOV W0, #%d", value & 0xFFFF)},
            {address = addr + 0x4, flags = 4, value = string.format("~A8 MOVK W0, #%d, LSL #16", (value >> 16) & 0xFFFF)},
            {address = addr + 0x8, flags = 4, value = "~A8 RET"}
        })
    end
end
-- Set up target game environment for memory patching
::GET_READY::
gg.setVisible(false)  -- Hide the GameGuardian UI
for i = 20, 100, 20 do
    gg.sleep(300)
    gg.toast(i .. "%")
end
local ti = gg.getTargetInfo()  -- Get target info (for 64-bit vs 32-bit detection)
local p_size = ti.x64 and 0x8 or 0x4  -- Determine pointer size

-- Define path to save offsets
local offsetFilePath = gg.EXT_FILES_DIR .. "/" .. APK .. "_Offsets.lua"

-- Functions to retrieve and manipulate memory values
local function getvalue(address, ggType)  -- Get memory value from a specified address
    return gg.getValues({{address = address, flags = ggType}})[1].value
end

local function ptr(address)  -- Get pointer value (32-bit or 64-bit)
    return getvalue(address, ti.x64 and gg.TYPE_QWORD or gg.TYPE_DWORD)
end

local function CString(address, str)  -- Compare string at address with the target string
    local bytes = gg.bytes(str)
    for i = 1, #bytes do
        if getvalue(address + i - 1, gg.TYPE_BYTE) & 0xFF ~= bytes[i] then
            return false
        end
    end
    return getvalue(address + #bytes, gg.TYPE_BYTE) == 0
end

-- Function to get a method from Il2Cpp by class and method name
local function GetIl2CppMethod(clazz, method)
    local result = {}
    gg.clearResults()
    gg.setRanges(gg.REGION_C_ALLOC | gg.REGION_ANONYMOUS | gg.REGION_OTHER | gg.REGION_CODE_APP | gg.REGION_C_BSS | gg.REGION_C_DATA)
    gg.searchNumber(string.format("Q 00 '%s' 00", method), gg.TYPE_BYTE)
    local count = gg.getResultsCount()

    if count > 0 then
        gg.refineNumber(method:byte(), gg.TYPE_BYTE)
        local t = gg.getResults(count)
        gg.searchPointer(0)
        t = gg.getResults(count)
        for _, v in ipairs(t) do
            if CString(ptr(ptr(v.address + p_size) + p_size * 2), clazz) then
                table.insert(result, {
                    address = ptr(v.address - p_size * 2),
                    name = string.format("%s :: %s", clazz, method),
                    flags = v.flags
                })
            end
        end
        gg.clearResults()
    end

    return result
end

-- Save and load offsets for methods
local function saveOffsetsToFile(offsets)
    local file = io.open(offsetFilePath, "w")
    file:write("-- "..APK.."\n-- Version : "..info.versionName.."\n")
    file:write("-- Script By : Your Name \n")
    file:write("-- "..string.rep("═─═", 5).."\n")
    for method, offset in pairs(offsets) do
        file:write(string.format("%s = %s\n", method, offset))
    end
    file:close()
end

local function loadOffsetsFromFile()
    local offsets = {}
    local file = io.open(offsetFilePath, "r")
    if file then
        for line in file:lines() do
            local method, offset = line:match("^(.-) = (.-)$")
            if method and offset then
                offsets[method] = offset
            end
        end
        file:close()
    end
    return offsets
end

-- Search for methods and save offsets if not already saved
local offsets = loadOffsetsFromFile()
if not next(offsets) then
    local Search = {
        [1] = {
        class = "Currency",  -- public class Currency
        method = "get_IsIAP" -- public bool get_IsIAP()
        },
        [2] = {
        class = "CharacterMotorAbilities", -- public class CharacterMotorAbilities 
        method = "get_JumpLimit"  -- public int get_JumpLimit()
        },
        -- add more class and method if needed 😉
    }

    -- Search for each method in the search table
    for i, v in ipairs(Search) do
        gg.toast(string.format("Searching [%s :: %s] (%d/%d)", v.class, v.method, i, #Search))
        gg.sleep(600)

        local results = GetIl2CppMethod(v.class, v.method)

        if #results > 0 then
            local offset = results[1].address - X_X[UwU]
            offsets[v.method] = string.format("0x%X", offset)
            _G[v.method] = offsets[v.method]
            gg.toast("✅ ["..v.method .. "] ✅")
        else
            offsets[v.method] = "nil"
            _G[v.method] = nil
            gg.toast("🚫 ["..v.method .. "] 🚫")
        end
        gg.sleep(1000)
    end

    saveOffsetsToFile(offsets)
else
-- If offsets are already saved, show them
local offsetDetails = {}
for method, offset in pairs(offsets) do
    table.insert(offsetDetails, string.format("%s: %s", method, offset))
    _G[method] = offset ~= "nil" and offset or nil
end

-- Generate the visual file structure
local relativePath = offsetFilePath:match("([^/]+/.+)")
local filePathStructure = "├─ 📁 " .. relativePath:gsub("/", "\n│ ├─ 📁 ")

local xXx = gg.alert(
    "🎲 Game : " .. APK ..
    "\n🪩 Offsets Saved File Found..!!" ..
    "\n" .. filePathStructure ..
    "\n" .. string.rep("─ ─", 7) ..  -- Adds a line 
    "\nOffsets : 📝\n" .. table.concat(offsetDetails, "\n"),
    "[ Start ]", nil, "[ Update ]"
)

if xXx == 3 then
    os.remove(offsetFilePath)
    goto GET_READY
end
end

-- Function to check if method offset is found, otherwise stop execution
function check(method)
    if not _G[method] then
        gg.alert("ERROR : [ "..method .. " ] Offset not found..!")
        gg.toast("⛔ This Hack Will Not Work ⛔")
        return nil
    end
    gg.toast("Hack [ON]")
    gg.sleep(1000)
    gg.toast("--( O_O )--")
    return true
end
gg.setVisible(true) -- Show Menu
-- ⬜⬜⬜⏪⬜⬜⬜⏩⬜⬜⬜
-- ⬜⬜⬜⏪⬜⬜⬜⏩⬜⬜⬜
-- O = offset (use Capital O)
-- X = value (use Capital X)
-- Arm() = Patch (Patch offset Value)
-- ============================
-- RecordOriginalValue(0x523368)  -- Record the original value
-- injectAssembly(0x522A24, false) -- false value
-- injectAssembly(0x2EB4F0, 999999999) -- Int Value
-- RevertValue(0x523368)  -- Revert the values
-- ⬜⬜⬜⏪⬜⬜⬜⏩⬜⬜⬜
-- ⬜⬜⬜⏪⬜⬜⬜⏩⬜⬜⬜


function A_ON() -- hack 1

   RecordOriginalValue(get_IsIAP) -- Record Value
   injectAssembly(get_IsIAP, false) -- Patch value
   -- false is our edit value
    
return true    
end


function A_OFF()

   RevertValue(get_IsIAP) -- Revert (Hack Off)
    
return nil
end

-- Hack 2 
function B_ON() 

   RecordOriginalValue(get_JumpLimit) -- Record Value
   injectAssembly(get_JumpLimit, 99999) -- Patch value
    
return true
end

function B_OFF()

   RevertValue(get_JumpLimit) -- Revert (Hack Off)
    
return nil
end


-- Main Menu --
menuList = {

    "Free Shop", -- 1
    "Unlimited Jump", -- 2
    "EXIT", -- 3
    
}

checkList = {

    nil, -- 1
    nil,  -- 2
    nil, -- 3
    
}
-- Done 😉
-- Menu Function
function menu()
    tsu = gg.multiChoice(menuList, checkList, "━━━━[ " .. APK .. " ]━━━━")
    if tsu == nil then return end

    -- Option 1: Check and toggle A
    if tsu[1] ~= checkList[1] then
        if tsu[1] == true then
            if check("get_IsIAP") then -- Check offset
                checkList[1] = A_ON()
            else
                gg.toast("$ ( X_X ) $") -- Error Toast
            end
        else
            checkList[1] = A_OFF()
        end
    end

    -- Option 2: Check and toggle B
    if tsu[2] ~= checkList[2] then
        if tsu[2] == true then
            if check("get_JumpLimit") then -- Check offset
                checkList[2] = B_ON()
            else
                gg.toast("$ ( X_X ) $") -- Error Toast
            end
        else
            checkList[2] = B_OFF()
        end
    end

    -- Option 3: Exit
    if tsu[3] == true then
        checkList[3] = Exit()
    end
end
-- Function to apply ARM patches
function Arm()
    O = tonumber(O)
    if O == nil then 
       return
    end
    for UwU = 1, #(X_X) do
        Dick = nil
        Dick = {}

        if type(X) ~= "table" then
            Dick[1] = {}
            Dick[2] = {}
            Dick[1].address = X_X[UwU] + O
            Dick[1].flags = 4
            if X == 0 then
                Dick[1].value = 'h000080D2'
            elseif X == 1 then
                Dick[1].value = 'h200080D2'
            else
                Dick[1].value = X
            end
            Dick[2].address = X_X[UwU] + (O + 4)
            Dick[2].flags = 4
            Dick[2].value = 'D65F03C0h'
        else
            Fuck = 0
            for Bitch = 1, #(X) do
                Dick[Bitch] = {}
                Dick[Bitch].address = X_X[UwU] + O + Fuck
                Dick[Bitch].flags = 4
                Dick[Bitch].value = tostring(X[Bitch])
                Fuck = Fuck + 4
            end
        end

        gg.setValues(Dick)
    end
end
-- ⬜⬜⬜⏪⬜⬜⬜⏩⬜⬜⬜
-- ⬜⬜⬜⏪⬜⬜⬜⏩⬜⬜⬜
-- Exit function
function Exit()
  print("🔳🔳🔳🔳🔳🔳🔳🔳🔳🔳🔳🔳🔳🔳🔳")
  print("🔳⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛🔳")
  print("🔳⬛⬛⬛⬛⬛🟥🟥🟥⬛⬛⬛⬛⬛🔳")
  print("🔳⬛⬛⬛⬛🟥🟥🟥🟥🟥⬛⬛⬛⬛🔳")
  print("🔳⬛⬛⬛🟥🟥🟥🟦🟦🟦⬛⬛⬛⬛🔳")
  print("🔳⬛⬛⬛🟥🟥🟥🟦🟦🟦⬛⬛⬛⬛🔳")
  print("🔳⬛⬛⬛🟥🟥🟥🟥🟥🟥⬛⬛⬛⬛🔳")
  print("🔳⬛⬛⬛🟥🟥🟥🟥🟥🟥⬛⬛⬛⬛🔳")
  print("🔳⬛⬛⬛⬛🟥🟥🟥🟥🟥⬛⬛⬛⬛🔳")
  print("🔳⬛⬛⬛⬛🟥🟥⬛🟥🟥⬛⬛⬛⬛🔳")
  print("🔳⬛⬛⬛⬛🟥🟥⬛🟥🟥⬛⬛⬛⬛🔳")
  print("🔳⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛🔳")
  print("🔳🔳🔳🔳🔳🔳🔳🔳🔳🔳🔳🔳🔳🔳🔳")
  os.exit()
end

-- Menu loop function
while true do
    if gg.isVisible(true) then
        gg.setVisible(false)
        menu()
    end
end


--end func src
end

gg.setVisible(false)
json = load(gg.makeRequest("https://raw.githubusercontent.com/rxi/json.lua/master/json.lua").content)()

local ipAddress = gg.makeRequest('http://checkip.dyndns.org/').content:match("%d+%.%d+%.%d+%.%d+")

if ipAddress then
    local vpnData = json.decode(gg.makeRequest('http://v2.api.iphub.info/ip/' .. ipAddress, {
        ['X-Key'] = "MjYxNDU6RXUzWEs3QkJHTXBOOWlOWWJMQllxd21veUI5MDhKSXQ="
    }).content)

    if vpnData and vpnData.block == 1 then
        while true do gg.alert("⚠️ VPN Or Proxy Detected ⚠️ \n\n🔒 Reject IP Address :" .. ipAddress .. "","Exit") break end
    else
        src()
        --gg.alert("🟢 No VPN Or Proxy Detected 🟢\n\n🔓 Accept IP Address : " .. ipAddress .. "","Next")
    end
else
    gg.alert("⚠️ IP Address Could Not Be Parsed ⚠️")
end
