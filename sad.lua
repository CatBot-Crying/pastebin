while pcall(load("os.exit()")) or not tostring(os.exit):find("gg%.exit") do gg.alert("Block GG Logger") end

a_rm = gg.getFile():match("[^/]*$")
if a_rm ~= "script.lua" then
    gg.alert("ERROR")
    os.exit()
    while true do end
end

-- Lock to Subway Surfers
local TARGET_PACKAGE = "com.kiloo.subwaysurf"
local libNameSo = "libil2cpp.so"
local info = gg.getTargetInfo()
if not info or info.packageName ~= TARGET_PACKAGE then
    gg.alert("This script is designed for Subway Surfers only! Current app: " .. (info and info.packageName or "None"))
    os.exit()
end


local info = gg.getTargetInfo()   -- Get information about the target app
local APK = info.label            -- Get APK name

-- Define tables and flags for memory handling
X_X = {}           -- Store memory range start addresses
UwU = 0            -- Counter for memory ranges
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
local Original = {}

local function RecordOriginalValue(offset)
    local REV = gg.getValues((function(R)
        for _, x in ipairs({offset}) do
            for i = 0, 16, 4 do
                R[#R + 1] = {address = X_X[UwU] + x + i, flags = 4}
            end
        end
        return R
    end)({}))
    Original[offset] = REV
end

local function RevertValue(offset)
    local originalValues = Original[offset]
    if originalValues then
        gg.setValues(originalValues)
        gg.toast("Hack [OFF]")
        gg.sleep(600)
        gg.toast("--( X_X )--")
    else
        gg.alert("⛔ ERROR : ORIGINAL VALUE NOT FOUND ⛔")
    end
end

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

::GET_READY::
gg.setVisible(false)
local frames = {"⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏"}
local progress = 0
while progress <= 100 do
    local bar = string.rep("█", progress // 10) .. string.rep("░", 10 - progress // 10)
    local frame = frames[(progress % #frames) + 1]
    gg.toast(string.format("%s Loading: [%s] %d%%", frame, bar, progress))
    gg.sleep(300)
    progress = progress + 10
end
gg.toast("🎉 Ready! 🎉")
gg.sleep(700)

local ti = gg.getTargetInfo()
local p_size = ti.x64 and 0x8 or 0x4
local offsetFilePath = gg.EXT_FILES_DIR .. "/" .. APK .. "_Offsets.lua"

local function getvalue(address, ggType)
    return gg.getValues({{address = address, flags = ggType}})[1].value
end

local function ptr(address)
    return getvalue(address, ti.x64 and gg.TYPE_QWORD or gg.TYPE_DWORD)
end

local function CString(address, str)
    local bytes = gg.bytes(str)
    for i = 1, #bytes do
        if getvalue(address + i - 1, gg.TYPE_BYTE) & 0xFF ~= bytes[i] then
            return false
        end
    end
    return getvalue(address + #bytes, gg.TYPE_BYTE) == 0
end

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

local function saveOffsetsToFile(offsets)
    local file = io.open(offsetFilePath, "w")
    file:write("-- "..APK.."\n-- Version : "..info.versionName.."\n")
    file:write("-- Script By : Your Name \n")
    file:write("-- "..string.rep("═─═", 7).."\n")
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

local offsets = loadOffsetsFromFile()
if not next(offsets) then
    local Search = {
        [1] = {class = "Currency", method = "get_IsIAP"},
        [2] = {class = "CharacterMotorAbilities", method = "get_JumpLimit"}
    }

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
        gg.sleep(600)
    end
    saveOffsetsToFile(offsets)
else
    local offsetDetails = {}
    for method, offset in pairs(offsets) do
        table.insert(offsetDetails, string.format("%s: %s", method, offset))
        _G[method] = offset ~= "nil" and offset or nil
    end
    local relativePath = offsetFilePath:match("([^/]+/.+)")
    local filePathStructure = "├─ 📁 " .. relativePath:gsub("/", "\n│ ├─ 📁 ")
    local xXx = gg.alert(
        "🎲 Game : " .. APK ..
        "\n🪩 Offsets Saved File Found..!!" ..
        "\n" .. filePathStructure ..
        "\n" .. string.rep("─ ─", 3) ..
        "\nOffsets : 📝\n" .. table.concat(offsetDetails, "\n"),
        "[ Start ]", nil, "[ Update ]"
    )
    if xXx == 3 then
        os.remove(offsetFilePath)
        goto GET_READY
    end
end

function check(method)
    if not _G[method] then
        gg.alert("ERROR : [ "..method .. " ] Offset not found..!")
        gg.toast("⛔ This Hack Will Not Work ⛔")
        return nil
    end
    gg.toast("Hack [ON]")
    gg.sleep(600)
    gg.toast("--( O_O )--")
    return true
end

gg.setVisible(true)

function A_ON()
    RecordOriginalValue(get_IsIAP)
    injectAssembly(get_IsIAP, false)
    return true
end

function A_OFF()
    RevertValue(get_IsIAP)
    return nil
end

function B_ON()
    RecordOriginalValue(get_JumpLimit)
    injectAssembly(get_JumpLimit, 99999)
    return true
end

function B_OFF()
    RevertValue(get_JumpLimit)
    return nil
end


menuList = {
    "💰 Free Shop",
    "🦘 Unlimited Jump",
    "🚪 EXIT"
}

checkList = {
    nil,
    nil,
    nil
}

function menu()
    local header = "\n " .. APK .. " [".. info.versionName .. "] \nBy: Saki \n"
    local styledMenu = {}
    for i, item in ipairs(menuList) do
        local status = checkList[i] and "✅ [ON]" or "❌ [OFF]"
        if i == #menuList then
            styledMenu[i] = item
        else
            styledMenu[i] = item .. " " .. status
        end
    end
    
    local choice = gg.choice(styledMenu, nil, header .. "\nSelect a feature:")
    if choice == nil then return end

    if choice == 1 then
        if not checkList[1] then
            if check("get_IsIAP") then
                checkList[1] = A_ON()
                gg.toast("💰 Free Shop Activated!")
            end
        else
            checkList[1] = A_OFF()
            gg.toast("💰 Free Shop Deactivated!")
        end
    end

    if choice == 2 then
        if not checkList[2] then
            if check("get_JumpLimit") then
                checkList[2] = B_ON()
                gg.toast("🦘 Unlimited Jump ON!")
            end
        else
            checkList[2] = B_OFF()
            gg.toast("🦘 Unlimited Jump OFF!")
        end
    end

    if choice == 3 then
        Exit()
    end
end


function Exit()
    local anim = {
        "🔳🔳🔳🔳🔳🔳🔳🔳🔳🔳🔳🔳🔳🔳🔳",
        "🔳⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛🔳",
        "🔳⬛⬛⬛⬛⬛🟥🟥🟥⬛⬛⬛⬛⬛🔳",
        "🔳⬛⬛⬛⬛🟥🟥🟥🟥🟥⬛⬛⬛⬛🔳",
        "🔳⬛⬛⬛🟥🟥🟥🟦🟦🟦⬛⬛⬛⬛🔳",
        "🔳⬛⬛⬛🟥🟥🟥🟦🟦🟦⬛⬛⬛⬛🔳",
        "🔳⬛⬛⬛🟥🟥🟥🟥🟥🟥⬛⬛⬛⬛🔳",
        "🔳⬛⬛⬛🟥🟥🟥🟥🟥🟥⬛⬛⬛⬛🔳",
        "🔳⬛⬛⬛⬛🟥🟥🟥🟥🟥⬛⬛⬛⬛🔳",
        "🔳⬛⬛⬛⬛🟥🟥⬛🟥🟥⬛⬛⬛⬛🔳",
        "🔳⬛⬛⬛⬛🟥🟥⬛🟥🟥⬛⬛⬛⬛🔳",
        "🔳⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛🔳",
        "🔳🔳🔳🔳🔳🔳🔳🔳🔳🔳🔳🔳🔳🔳🔳"
    }
    for i = #anim, 1, -1 do
        print(anim[i])
        gg.sleep(100)
    end
    gg.toast("👋 Goodbye!")
    gg.sleep(500)
    os.exit()
end

while true do
    if gg.isVisible(true) then
        gg.setVisible(false)
        gg.toast("🎮 Opening Menu...")
        gg.sleep(300)
        menu()
    end
    gg.sleep(100)
end
