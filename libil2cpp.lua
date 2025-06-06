local LibNameUnityOnly ="libil2cpp.so"
local __bundle_require, __bundle_loaded, __bundle_register, __bundle_modules = (function(superRequire)
local loadingPlaceholder = {[{}] = true}
local register
local modules = {}
local require
local loaded = {}
register = function(name, body)
if not modules[name] then
modules[name] = body
end
end
require = function(name)
local loadedModule = loaded[name]
if loadedModule then
if loadedModule == loadingPlaceholder then
return nil
end
else
if not modules[name] then
if not superRequire then
local identifier = type(name) == 'string' and '\"' .. name .. '\"' or tostring(name)
error('Tried to require ' .. identifier .. ', but no such module has been registered')
else
return superRequire(name)
end
end
loaded[name] = loadingPlaceholder
loadedModule = modules[name](require, loaded, register, modules)
loaded[name] = loadedModule
end
return loadedModule
end
return require, loaded, register, modules
end)(require)
__bundle_register("GGIl2cpp", function(require, _LOADED, __bundle_register, __bundle_modules)
require("utils.il2cppconst")
require("il2cpp")
return Il2cpp
end)
__bundle_register("il2cpp", function(require, _LOADED, __bundle_register, __bundle_modules)
local Il2cppMemory = require("utils.il2cppmemory")
local VersionEngine = require("utils.version")
local AndroidInfo = require("utils.androidinfo")
local Searcher = require("utils.universalsearcher")
local PatchApi = require("utils.patchapi")
local Il2cppBase = {
il2cppStart = 0,
il2cppEnd = 0,
globalMetadataStart = 0,
globalMetadataEnd = 0,
globalMetadataHeader = 0,
MainType = AndroidInfo.platform and gg.TYPE_QWORD or gg.TYPE_DWORD,
pointSize = AndroidInfo.platform and 8 or 4,
Il2CppTypeDefinitionApi = {},
MetadataRegistrationApi = require("il2cppstruct.metadataRegistration"),
TypeApi = require("il2cppstruct.type"),
MethodsApi = require("il2cppstruct.method"),
GlobalMetadataApi = require("il2cppstruct.globalmetadata"),
FieldApi = require("il2cppstruct.field"),
ClassApi = require("il2cppstruct.class"),
ObjectApi = require("il2cppstruct.object"),
ClassInfoApi = require("il2cppstruct.api.classinfo"),
FieldInfoApi = require("il2cppstruct.api.fieldinfo"),
String = require("il2cppstruct.il2cppstring"),
MemoryManager = require("utils.malloc"),
PatchesAddress = function(add, Bytescodes)
local patchCode = {}
for code in string.gmatch(Bytescodes, '.') do
patchCode[#patchCode + 1] = {
address = add + #patchCode,
value = string.byte(code),
flags = gg.TYPE_BYTE
}
end
local patch = PatchApi:Create(patchCode)
patch:Patch()
return patch
end,
FindMethods = function(searchParams)
Il2cppMemory:SaveResults()
for i = 1, #searchParams do
searchParams[i] = Il2cpp.MethodsApi:Find(searchParams[i])
end
Il2cppMemory:ClearSavedResults()
return searchParams
end,
FindClass = function(searchParams)
Il2cppMemory:SaveResults()
for i = 1, #searchParams do
searchParams[i] = Il2cpp.ClassApi:Find(searchParams[i])
end
Il2cppMemory:ClearSavedResults()
return searchParams
end,
FindObject = function(searchParams)
Il2cppMemory:SaveResults()
for i = 1, #searchParams do
searchParams[i] = Il2cpp.ObjectApi:Find(Il2cpp.ClassApi:Find({Class = searchParams[i]}))
end
Il2cppMemory:ClearSavedResults()
return searchParams
end,
FindFields = function(searchParams)
Il2cppMemory:SaveResults()
for i = 1, #searchParams do
local searchParam = searchParams[i]
local searchResult = Il2cppMemory:GetInformationOfField(searchParam)
if not searchResult then
searchResult = Il2cpp.FieldApi:Find(searchParam)
Il2cppMemory:SetInformationOfField(searchParam, searchResult)
end
searchParams[i] = searchResult
end
Il2cppMemory:ClearSavedResults()
return searchParams
end,
Utf8ToString = function(Address, length)
local chars, char = {}, {
address = Address,
flags = gg.TYPE_BYTE
}
if not length then
repeat
_char = string.char(gg.getValues({char})[1].value & 0xFF)
chars[#chars + 1] = _char
char.address = char.address + 0x1
until string.find(_char, "[%z%s]")
return table.concat(chars, "", 1, #chars - 1)
else
for i = 1, length do
local _char = gg.getValues({char})[1].value
chars[i] = string.char(_char & 0xFF)
char.address = char.address + 0x1
end
return table.concat(chars)
end
end,
ChangeBytesOrder = function(bytes)
local newBytes, index, lenBytes = {}, 0, #bytes / 2
for byte in string.gmatch(bytes, "..") do
newBytes[lenBytes - index] = byte
index = index + 1
end
return table.concat(newBytes)
end,
FixValue = function(val)
return AndroidInfo.platform and val & 0x00FFFFFFFFFFFFFF or val & 0xFFFFFFFF
end,
GetValidAddress = function(Address)
local lastByte = Address & 0x000000000000000F
local delta = 0
local checkTable = {[12] = true, [4] = true, [8] = true, [0] = true}
while not checkTable[lastByte - delta] do
delta = delta + 1
end
return Address - delta
end,
SearchPointer = function(self, address)
address = self.ChangeBytesOrder(type(address) == 'number' and string.format('%X', address) or address)
gg.searchNumber('h ' .. address)
gg.refineNumber('h ' .. address:sub(1, 6))
gg.refineNumber('h ' .. address:sub(1, 2))
local FindsResult = gg.getResults(gg.getResultsCount())
gg.clearResults()
return FindsResult
end,
}
Il2cpp = setmetatable({}, {
__call = function(self, config)
config = config or {}
getmetatable(self).__index = Il2cppBase
if config.libilcpp then
self.il2cppStart, self.il2cppEnd = config.libilcpp.start, config.libilcpp['end']
else
self.il2cppStart, self.il2cppEnd = Searcher.FindIl2cpp()
end
if config.globalMetadata then
self.globalMetadataStart, self.globalMetadataEnd = config.globalMetadata.start, config.globalMetadata['end']
else
self.globalMetadataStart, self.globalMetadataEnd = Searcher:FindGlobalMetaData()
end
if config.globalMetadataHeader then
self.globalMetadataHeader = config.globalMetadataHeader
else
self.globalMetadataHeader = self.globalMetadataStart
end
self.MetadataRegistrationApi.metadataRegistration = config.metadataRegistration
VersionEngine:ChooseVersion(config.il2cppVersion, self.globalMetadataHeader)
Il2cppMemory:ClearMemorize()
end,
__index = function(self, key)
assert(key == "PatchesAddress", "You didn't call 'Il2cpp'")
return Il2cppBase[key]
end
})
return Il2cpp
end)
__bundle_register("utils.malloc", function(require, _LOADED, __bundle_register, __bundle_modules)
local MemoryManager = {
availableMemory = 0,
lastAddress = 0,
NewAlloc = function(self)
self.lastAddress = gg.allocatePage(gg.PROT_READ | gg.PROT_WRITE)
self.availableMemory = 4096
end,
}
local M = {
MAlloc = function(size)
local manager = MemoryManager
if size > manager.availableMemory then
manager:NewAlloc()
end
local address = manager.lastAddress
manager.availableMemory = manager.availableMemory - size
manager.lastAddress = manager.lastAddress + size
return address
end,
}
return M
end)
__bundle_register("il2cppstruct.il2cppstring", function(require, _LOADED, __bundle_register, __bundle_modules)
local StringApi = {
EditString = function(self, newStr)
local _stringLength = gg.getValues{{address = self.address + self.Fields._stringLength, flags = gg.TYPE_DWORD}}[1].value
_stringLength = _stringLength * 2
local bytes = gg.bytes(newStr, "UTF-16LE")
if _stringLength == #bytes then
local strStart = self.address + self.Fields._firstChar
for i, v in ipairs(bytes) do
bytes[i] = {
address = strStart + (i - 1),
flags = gg.TYPE_BYTE,
value = v
}
end
gg.setValues(bytes)
elseif _stringLength > #bytes then
local strStart = self.address + self.Fields._firstChar
local _bytes = {}
for i = 1, _stringLength do
_bytes[#_bytes + 1] = {
address = strStart + (i - 1),
flags = gg.TYPE_BYTE,
value = bytes[i] or 0
}
end
gg.setValues(_bytes)
elseif _stringLength < #bytes then
self.address = Il2cpp.MemoryManager.MAlloc(self.Fields._firstChar + #bytes + 8)
local length = #bytes % 2 == 1 and #bytes + 1 or #bytes
local _bytes = {
{ address = self.address,
flags = Il2cpp.MainType,
value = self.ClassAddress
},
{ address = self.address + self.Fields._stringLength,
flags = gg.TYPE_DWORD,
value = length / 2
}
}
local strStart = self.address + self.Fields._firstChar
for i = 1, length do
_bytes[#_bytes + 1] = {
address = strStart + (i - 1),
flags = gg.TYPE_BYTE,
value = bytes[i] or 0
}                
end
_bytes[#_bytes + 1] = {
address = self.pointToStr,
flags = Il2cpp.MainType,
value = self.address
}
gg.setValues(_bytes)
end
end,
ReadString = function(self)
local _stringLength = gg.getValues{{address = self.address + self.Fields._stringLength, flags = gg.TYPE_DWORD}}[1].value
local bytes = {}
if _stringLength > 0 and _stringLength < 200 then
local strStart = self.address + self.Fields._firstChar
for i = 0, _stringLength do
bytes[#bytes + 1] = {
address = strStart + (i << 1),
flags = gg.TYPE_WORD
}
end
bytes = gg.getValues(bytes)
local code = {[[return "]]}
for i, v in ipairs(bytes) do
code[#code + 1] = string.format([[\u{%x}]], v.value & 0xFFFF)
end
code[#code + 1] = '"'
local read, err = load(table.concat(code))
if read then
return read()
end
end
return ""
end
}
local String = {
From = function(address)
local pointToStr = gg.getValues({{address = Il2cpp.FixValue(address), flags = Il2cpp.MainType}})[1]
local str = setmetatable(
{
address = Il2cpp.FixValue(pointToStr.value), 
Fields = {},
pointToStr = Il2cpp.FixValue(address)
}, {__index = StringApi})
local pointClassAddress = gg.getValues({{address = str.address, flags = Il2cpp.MainType}})[1].value
local stringInfo = Il2cpp.FindClass({{Class = Il2cpp.FixValue(pointClassAddress), FieldsDump = true}})[1]
for i, v in ipairs(stringInfo) do
if v.ClassNameSpace == "System" then
str.ClassAddress = tonumber(v.ClassAddress, 16)
for indexField, FieldInfo in ipairs(v.Fields) do
str.Fields[FieldInfo.FieldName] = tonumber(FieldInfo.Offset, 16)
end
return str
end
end
return nil
end,
}
return String
end)
__bundle_register("il2cppstruct.api.fieldinfo", function(require, _LOADED, __bundle_register, __bundle_modules)
local Il2cppMemory = require("utils.il2cppmemory")
local FieldInfoApi = {
GetConstValue = function(self)
if self.IsConst then
local fieldIndex = getmetatable(self).fieldIndex
local defaultValue = Il2cppMemory:GetDefaultValue(fieldIndex)
if not defaultValue then
defaultValue = Il2cpp.GlobalMetadataApi:GetDefaultFieldValue(fieldIndex)
Il2cppMemory:SetDefaultValue(fieldIndex, defaultValue)
elseif defaultValue == "nil" then
return nil
end
return defaultValue
end
return nil
end
}
return FieldInfoApi
end)
__bundle_register("utils.il2cppmemory", function(require, _LOADED, __bundle_register, __bundle_modules)
local Il2cppMemory = {
Methods = {},
Classes = {},
Fields = {},
DefaultValues = {},
Results = {},
Types = {},
GetInformationOfType = function(self, index)
return self.Types[index]
end,
SetInformationOfType = function(self, index, typeName)
self.Types[index] = typeName
end,
SaveResults = function(self)
if gg.getResultsCount() > 0 then
self.Results = gg.getResults(gg.getResultsCount())
end
end,
ClearSavedResults = function(self)
self.Results = {}
end,
GetDefaultValue = function(self, fieldIndex)
return self.DefaultValues[fieldIndex]
end,
SetDefaultValue = function(self, fieldIndex, defaultValue)
self.DefaultValues[fieldIndex] = defaultValue or "nil"
end,
GetInformationOfField = function(self, searchParam)
return self.Fields[searchParam]
end,
SetInformationOfField = function(self, searchParam, searchResult)
if not searchResult.Error then
self.Fields[searchParam] = searchResult
end
end,
GetInformaionOfMethod = function(self, searchParam)
return self.Methods[searchParam]
end,
SetInformaionOfMethod = function(self, searchParam, searchResult)
if not searchResult.Error then
self.Methods[searchParam] = searchResult
end
end,
GetInformationOfClass = function(self, searchParam)
return self.Classes[searchParam]
end,
SetInformationOfClass = function(self, searchParam, searchResult)
self.Classes[searchParam] = searchResult
end,
ClearMemorize = function(self)
self.Methods = {}
self.Classes = {}
self.Fields = {}
self.DefaultValues = {}
self.Results = {}
self.Types = {}
end
}
return Il2cppMemory
end)
__bundle_register("il2cppstruct.api.classinfo", function(require, _LOADED, __bundle_register, __bundle_modules)
local ClassInfoApi = {
GetFieldWithName = function(self, name)
local FieldsInfo = self.Fields
if FieldsInfo then
for fieldIndex = 1, #FieldsInfo do
if FieldsInfo[fieldIndex].FieldName == name then
return FieldsInfo[fieldIndex]
end
end
else
local ClassAddress = tonumber(self.ClassAddress, 16)
local _ClassInfo = gg.getValues({
{ address = ClassAddress + Il2cpp.ClassApi.FieldsLink,
flags = Il2cpp.MainType
},
{ address = ClassAddress + Il2cpp.ClassApi.CountFields,
flags = gg.TYPE_WORD
}
})
self.Fields = Il2cpp.ClassApi:GetClassFields(Il2cpp.FixValue(_ClassInfo[1].value), _ClassInfo[2].value, {
ClassName = self.ClassName,
IsEnum = self.IsEnum,
TypeMetadataHandle = self.TypeMetadataHandle
})
return self:GetFieldWithName(name)
end
return nil
end,
GetMethodsWithName = function(self, name)
local MethodsInfo, MethodsInfoResult = self.Methods, {}
if MethodsInfo then
for methodIndex = 1, #MethodsInfo do
if MethodsInfo[methodIndex].MethodName == name then
MethodsInfoResult[#MethodsInfoResult + 1] = MethodsInfo[methodIndex]
end
end
return MethodsInfoResult
else
local ClassAddress = tonumber(self.ClassAddress, 16)
local _ClassInfo = gg.getValues({
{ address = ClassAddress + Il2cpp.ClassApi.MethodsLink,
flags = Il2cpp.MainType
},
{ address = ClassAddress + Il2cpp.ClassApi.CountMethods,
flags = gg.TYPE_WORD
}
})
self.Methods = Il2cpp.ClassApi:GetClassMethods(Il2cpp.FixValue(_ClassInfo[1].value), _ClassInfo[2].value,
self.ClassName)
return self:GetMethodsWithName(name)
end
end,
GetFieldWithOffset = function(self, fieldOffset)
if not self.Fields then
local ClassAddress = tonumber(self.ClassAddress, 16)
local _ClassInfo = gg.getValues({
{ address = ClassAddress + Il2cpp.ClassApi.FieldsLink,
flags = Il2cpp.MainType
},
{ address = ClassAddress + Il2cpp.ClassApi.CountFields,
flags = gg.TYPE_WORD
}
})
self.Fields = Il2cpp.ClassApi:GetClassFields(Il2cpp.FixValue(_ClassInfo[1].value), _ClassInfo[2].value, {
ClassName = self.ClassName,
IsEnum = self.IsEnum,
TypeMetadataHandle = self.TypeMetadataHandle
})
end
if #self.Fields > 0 then
local klass = self
while klass ~= nil do
if klass.Fields and klass.InstanceSize >= fieldOffset then
local lastField
for indexField, field in ipairs(klass.Fields) do
if not (field.IsStatic or field.IsConst) then
local offset = tonumber(field.Offset, 16)
if offset > 0 then 
local maybeStruct = fieldOffset < offset
if indexField == 1 and maybeStruct then
break
elseif offset == fieldOffset or indexField == #klass.Fields then
return field
elseif maybeStruct then
return lastField
else
lastField = field
end
end
end
end
end
klass = klass.Parent ~= nil 
and Il2cpp.FindClass({
{
Class = tonumber(klass.Parent.ClassAddress, 16), 
FieldsDump = true
}
})[1][1] 
or nil
end
end
return nil
end
}
return ClassInfoApi
end)
__bundle_register("il2cppstruct.object", function(require, _LOADED, __bundle_register, __bundle_modules)
local AndroidInfo = require("utils.androidinfo")
local ObjectApi = {
FilterObjects = function(self, Objects)
local FilterObjects = {}
for k, v in ipairs(gg.getValuesRange(Objects)) do
if v == 'A' then
FilterObjects[#FilterObjects + 1] = Objects[k]
end
end
Objects = FilterObjects
gg.loadResults(Objects)
gg.searchPointer(0)
if gg.getResultsCount() <= 0 and AndroidInfo.platform and AndroidInfo.sdk >= 30 then
local FixRefToObjects = {}
for k, v in ipairs(Objects) do
gg.searchNumber(tostring(v.address | 0xB400000000000000), gg.TYPE_QWORD)
local RefToObject = gg.getResults(gg.getResultsCount())
table.move(RefToObject, 1, #RefToObject, #FixRefToObjects + 1, FixRefToObjects)
gg.clearResults()
end
gg.loadResults(FixRefToObjects)
end
local RefToObjects, FilterObjects = gg.getResults(gg.getResultsCount()), {}
gg.clearResults()
for k, v in ipairs(gg.getValuesRange(RefToObjects)) do
if v == 'A' then
FilterObjects[#FilterObjects + 1] = {
address = Il2cpp.FixValue(RefToObjects[k].value),
flags = RefToObjects[k].flags
}
end
end
gg.loadResults(FilterObjects)
local _FilterObjects = gg.getResults(gg.getResultsCount())
gg.clearResults()
return _FilterObjects
end,
FindObjects = function(self, ClassAddress)
gg.clearResults()
gg.setRanges(0)
gg.setRanges(gg.REGION_C_HEAP | gg.REGION_C_HEAP | gg.REGION_ANONYMOUS | gg.REGION_C_BSS | gg.REGION_C_DATA |
gg.REGION_C_ALLOC)
gg.loadResults({{
address = tonumber(ClassAddress, 16),
flags = Il2cpp.MainType
}})
gg.searchPointer(0)
if gg.getResultsCount() <= 0 and AndroidInfo.platform and AndroidInfo.sdk >= 30 then
gg.searchNumber(tostring(tonumber(ClassAddress, 16) | 0xB400000000000000), gg.TYPE_QWORD)
end
local FindsResult = gg.getResults(gg.getResultsCount())
gg.clearResults()
return self:FilterObjects(FindsResult)
end,
Find = function(self, ClassesInfo)
local Objects = {}
for j = 1, #ClassesInfo do
local FindResult = self:FindObjects(ClassesInfo[j].ClassAddress)
table.move(FindResult, 1, #FindResult, #Objects + 1, Objects)
end
return Objects
end,
FindHead = function(Address)
local validAddress = Il2cpp.GetValidAddress(Address)
local mayBeHead = {}
for i = 1, 1000 do
mayBeHead[i] = {
address = validAddress - (4 * (i - 1)),
flags = Il2cpp.MainType
} 
end
mayBeHead = gg.getValues(mayBeHead)
for i = 1, #mayBeHead do
local mayBeClass = Il2cpp.FixValue(mayBeHead[i].value)
if Il2cpp.ClassApi.IsClassInfo(mayBeClass) then
return mayBeHead[i]
end
end
return {value = 0, address = 0}
end,
}
return ObjectApi
end)
__bundle_register("utils.androidinfo", function(require, _LOADED, __bundle_register, __bundle_modules)
local AndroidInfo = {
platform = gg.getTargetInfo().x64,
sdk = gg.getTargetInfo().targetSdkVersion
}
return AndroidInfo
end)
__bundle_register("il2cppstruct.class", function(require, _LOADED, __bundle_register, __bundle_modules)
local Protect = require("utils.protect")
local StringUtils = require("utils.stringutils")
local Il2cppMemory = require("utils.il2cppmemory")
local ClassApi = {
GetClassName = function(self, ClassAddress)
return Il2cpp.Utf8ToString(Il2cpp.FixValue(gg.getValues({{
address = Il2cpp.FixValue(ClassAddress) + self.NameOffset,
flags = Il2cpp.MainType
}})[1].value))
end,
GetClassMethods = function(self, MethodsLink, Count, ClassName)
local MethodsInfo, _MethodsInfo = {}, {}
for i = 0, Count - 1 do
_MethodsInfo[#_MethodsInfo + 1] = {
address = MethodsLink + (i << self.MethodsStep),
flags = Il2cpp.MainType
}
end
_MethodsInfo = gg.getValues(_MethodsInfo)
for i = 1, #_MethodsInfo do
local MethodInfo
MethodInfo, _MethodsInfo[i] = Il2cpp.MethodsApi:UnpackMethodInfo({
MethodInfoAddress = Il2cpp.FixValue(_MethodsInfo[i].value),
ClassName = ClassName
})
table.move(MethodInfo, 1, #MethodInfo, #MethodsInfo + 1, MethodsInfo)
end
MethodsInfo = gg.getValues(MethodsInfo)
Il2cpp.MethodsApi:DecodeMethodsInfo(_MethodsInfo, MethodsInfo)
return _MethodsInfo
end,
GetClassFields = function(self, FieldsLink, Count, ClassCharacteristic)
local FieldsInfo, _FieldsInfo = {}, {}
for i = 0, Count - 1 do
_FieldsInfo[#_FieldsInfo + 1] = {
address = FieldsLink + (i * self.FieldsStep),
flags = Il2cpp.MainType
}
end
_FieldsInfo = gg.getValues(_FieldsInfo)
for i = 1, #_FieldsInfo do
local FieldInfo
FieldInfo = Il2cpp.FieldApi:UnpackFieldInfo(Il2cpp.FixValue(_FieldsInfo[i].address))
table.move(FieldInfo, 1, #FieldInfo, #FieldsInfo + 1, FieldsInfo)
end
FieldsInfo = gg.getValues(FieldsInfo)
_FieldsInfo = Il2cpp.FieldApi:DecodeFieldsInfo(FieldsInfo, ClassCharacteristic)
return _FieldsInfo
end,
UnpackClassInfo = function(self, ClassInfo, Config)
local _ClassInfo = gg.getValues({
{ address = ClassInfo.ClassInfoAddress + self.NameOffset,
flags = Il2cpp.MainType
},
{ address = ClassInfo.ClassInfoAddress + self.CountMethods,
flags = gg.TYPE_WORD
},
{ address = ClassInfo.ClassInfoAddress + self.CountFields,
flags = gg.TYPE_WORD
},
{ address = ClassInfo.ClassInfoAddress + self.MethodsLink,
flags = Il2cpp.MainType
},
{ address = ClassInfo.ClassInfoAddress + self.FieldsLink,
flags = Il2cpp.MainType
},
{ address = ClassInfo.ClassInfoAddress + self.ParentOffset,
flags = Il2cpp.MainType
},
{ address = ClassInfo.ClassInfoAddress + self.NameSpaceOffset,
flags = Il2cpp.MainType
},
{ address = ClassInfo.ClassInfoAddress + self.StaticFieldDataOffset,
flags = Il2cpp.MainType
},
{ address = ClassInfo.ClassInfoAddress + self.EnumType,
flags = gg.TYPE_BYTE
},
{ address = ClassInfo.ClassInfoAddress + self.TypeMetadataHandle,
flags = Il2cpp.MainType
},
{ address = ClassInfo.ClassInfoAddress + self.InstanceSize,
flags = gg.TYPE_DWORD
},
{ address = ClassInfo.ClassInfoAddress + self.Token,
flags = gg.TYPE_DWORD
}
})
local ClassName = ClassInfo.ClassName or Il2cpp.Utf8ToString(Il2cpp.FixValue(_ClassInfo[1].value))
local ClassCharacteristic = {
ClassName = ClassName,
IsEnum = ((_ClassInfo[9].value >> self.EnumRsh) & 1) == 1,
TypeMetadataHandle = Il2cpp.FixValue(_ClassInfo[10].value)
}
return setmetatable({
ClassName = ClassName,
ClassAddress = string.format('%X', Il2cpp.FixValue(ClassInfo.ClassInfoAddress)),
Methods = (_ClassInfo[2].value > 0 and Config.MethodsDump) and
self:GetClassMethods(Il2cpp.FixValue(_ClassInfo[4].value), _ClassInfo[2].value, ClassName) or nil,
Fields = (_ClassInfo[3].value > 0 and Config.FieldsDump) and
self:GetClassFields(Il2cpp.FixValue(_ClassInfo[5].value), _ClassInfo[3].value, ClassCharacteristic) or
nil,
Parent = _ClassInfo[6].value ~= 0 and {
ClassAddress = string.format('%X', Il2cpp.FixValue(_ClassInfo[6].value)),
ClassName = self:GetClassName(_ClassInfo[6].value)
} or nil,
ClassNameSpace = Il2cpp.Utf8ToString(Il2cpp.FixValue(_ClassInfo[7].value)),
StaticFieldData = _ClassInfo[8].value ~= 0 and Il2cpp.FixValue(_ClassInfo[8].value) or nil,
IsEnum = ClassCharacteristic.IsEnum,
TypeMetadataHandle = ClassCharacteristic.TypeMetadataHandle,
InstanceSize = _ClassInfo[11].value,
Token = string.format("0x%X", _ClassInfo[12].value),
ImageName = ClassInfo.ImageName
}, {
__index = Il2cpp.ClassInfoApi,
__tostring = StringUtils.ClassInfoToDumpCS
})
end,
IsClassInfo = function(Address)
local imageAddress = Il2cpp.FixValue(gg.getValues(
{
{
address = Il2cpp.FixValue(Address),
flags = Il2cpp.MainType
}
}
)[1].value)
local imageStr = Il2cpp.Utf8ToString(Il2cpp.FixValue(gg.getValues(
{
{
address = imageAddress,
flags = Il2cpp.MainType
}
}
)[1].value))
local check = string.find(imageStr, ".-%.dll") or string.find(imageStr, "__Generated")
return check and imageStr or nil
end,
FindClassWithName = function(self, ClassName, searchResult)
local ClassNamePoint = Il2cpp.GlobalMetadataApi.GetPointersToString(ClassName)
local ResultTable = {}
if #ClassNamePoint > searchResult.len then
for classPointIndex, classPoint in ipairs(ClassNamePoint) do
local classAddress = classPoint.address - self.NameOffset
local imageName = self.IsClassInfo(classAddress)
if (imageName) then
ResultTable[#ResultTable + 1] = {
ClassInfoAddress = Il2cpp.FixValue(classAddress),
ClassName = ClassName,
ImageName = imageName
}
end
end
searchResult.len = #ClassNamePoint
else
searchResult.isNew = false
end
assert(#ResultTable > 0, string.format("The '%s' class is not initialized", ClassName))
return ResultTable
end,
FindClassWithAddressInMemory = function(self, ClassAddress, searchResult)
local ResultTable = {}
if searchResult.len < 1 then
local imageName = self.IsClassInfo(ClassAddress)
if imageName then
ResultTable[#ResultTable + 1] = {
ClassInfoAddress = ClassAddress,
ImageName = imageName
}
end
searchResult.len = 1
else
searchResult.isNew = false
end
assert(#ResultTable > 0, string.format("nothing was found for this address 0x%X", ClassAddress))
return ResultTable
end,
FindParamsCheck = {
['number'] = function(self, _class, searchResult)
return Protect:Call(self.FindClassWithAddressInMemory, self, _class, searchResult)
end,
['string'] = function(self, _class, searchResult)
return Protect:Call(self.FindClassWithName, self, _class, searchResult)
end,
['default'] = function()
return {
Error = 'Invalid search criteria'
}
end
},
Find = function(self, class)
local searchResult = Il2cppMemory:GetInformationOfClass(class.Class)
if (not searchResult) 
or ((class.FieldsDump or class.MethodsDump)
and (searchResult.config.FieldsDump ~= class.FieldsDump or searchResult.config.MethodsDump ~= class.MethodsDump))  
then
searchResult = {len = 0}
end
searchResult.isNew = true
local ClassInfo =
(self.FindParamsCheck[type(class.Class)] or self.FindParamsCheck['default'])(self, class.Class, searchResult)
if searchResult.isNew then
for k = 1, #ClassInfo do
ClassInfo[k] = self:UnpackClassInfo(ClassInfo[k], {
FieldsDump = class.FieldsDump,
MethodsDump = class.MethodsDump
})
end
searchResult.config = {
Class = class.Class,
FieldsDump = class.FieldsDump,
MethodsDump = class.MethodsDump
}
searchResult.result = ClassInfo
Il2cppMemory:SetInformationOfClass(class.Class, searchResult)
else
ClassInfo = searchResult.result
end
return ClassInfo
end
}
return ClassApi
end)
__bundle_register("utils.stringutils", function(require, _LOADED, __bundle_register, __bundle_modules)
local StringUtils = {
ClassInfoToDumpCS = function(classInfo)
local dumpClass = {
"// ", classInfo.ImageName, "\n",
"// Namespace: ", classInfo.ClassNameSpace, "\n";
"class ", classInfo.ClassName, classInfo.Parent and " : " .. classInfo.Parent.ClassName or "", "\n", 
"{\n"
}
if classInfo.Fields and #classInfo.Fields > 0 then
dumpClass[#dumpClass + 1] = "\n\t// Fields\n"
for i, v in ipairs(classInfo.Fields) do
local dumpField = {
"\t", v.Access, " ", v.IsStatic and "static " or "", v.IsConst and "const " or "", v.Type, " ", v.FieldName, "; // 0x", v.Offset, "\n"
}
table.move(dumpField, 1, #dumpField, #dumpClass + 1, dumpClass)
end
end
if classInfo.Methods and #classInfo.Methods > 0 then
dumpClass[#dumpClass + 1] = "\n\t// Methods\n"
for i, v in ipairs(classInfo.Methods) do
local dumpMethod = {
i == 1 and "" or "\n",
"\t// Offset: 0x", v.Offset, " VA: 0x", v.AddressInMemory, " ParamCount: ", v.ParamCount, "\n",
"\t", v.Access, " ",  v.IsStatic and "static " or "", v.IsAbstract and "abstract " or "", v.ReturnType, " ", v.MethodName, "() { } \n"
}
table.move(dumpMethod, 1, #dumpMethod, #dumpClass + 1, dumpClass)
end
end
table.insert(dumpClass, "\n}\n")
return table.concat(dumpClass)
end
}
return StringUtils
end)
__bundle_register("utils.protect", function(require, _LOADED, __bundle_register, __bundle_modules)
local Protect = {
ErrorHandler = function(err)
return {Error = err}
end,
Call = function(self, fun, ...) 
return ({xpcall(fun, self.ErrorHandler, ...)})[2]
end
}
return Protect
end)
__bundle_register("il2cppstruct.field", function(require, _LOADED, __bundle_register, __bundle_modules)
local Protect = require("utils.protect")
local FieldApi = {
UnpackFieldInfo = function(self, FieldInfoAddress)
return {
{ address = FieldInfoAddress,
flags = Il2cpp.MainType
}, 
{ address = FieldInfoAddress + self.Offset,
flags = gg.TYPE_WORD
}, 
{ address = FieldInfoAddress + self.Type,
flags = Il2cpp.MainType
}, 
{ address = FieldInfoAddress + self.ClassOffset,
flags = Il2cpp.MainType
}
}
end,
DecodeFieldsInfo = function(self, FieldsInfo, ClassCharacteristic)
local index, _FieldsInfo = 0, {}
local fieldStart = gg.getValues({{
address = ClassCharacteristic.TypeMetadataHandle + Il2cpp.Il2CppTypeDefinitionApi.fieldStart,
flags = gg.TYPE_DWORD
}})[1].value
for i = 1, #FieldsInfo, 4 do
index = index + 1
local TypeInfo = Il2cpp.FixValue(FieldsInfo[i + 2].value)
local _TypeInfo = gg.getValues({
{ address = TypeInfo + self.Type,
flags = gg.TYPE_WORD
}, 
{ address = TypeInfo + Il2cpp.TypeApi.Type,
flags = gg.TYPE_BYTE
}, 
{ address = TypeInfo,
flags = Il2cpp.MainType
}
})
local attrs = _TypeInfo[1].value
local IsConst = (attrs & Il2CppFlags.Field.FIELD_ATTRIBUTE_LITERAL) ~= 0
_FieldsInfo[index] = setmetatable({
ClassName = ClassCharacteristic.ClassName or Il2cpp.ClassApi:GetClassName(FieldsInfo[i + 3].value),
ClassAddress = string.format('%X', Il2cpp.FixValue(FieldsInfo[i + 3].value)),
FieldName = Il2cpp.Utf8ToString(Il2cpp.FixValue(FieldsInfo[i].value)),
Offset = string.format('%X', FieldsInfo[i + 1].value),
IsStatic = (not IsConst) and ((attrs & Il2CppFlags.Field.FIELD_ATTRIBUTE_STATIC) ~= 0),
Type = Il2cpp.TypeApi:GetTypeName(_TypeInfo[2].value, _TypeInfo[3].value),
IsConst = IsConst,
Access = Il2CppFlags.Field.Access[attrs & Il2CppFlags.Field.FIELD_ATTRIBUTE_FIELD_ACCESS_MASK] or "",
}, {
__index = Il2cpp.FieldInfoApi,
fieldIndex = fieldStart + index - 1
})
end
return _FieldsInfo
end,
FindFieldWithName = function(self, fieldName)
local fieldNamePoint = Il2cpp.GlobalMetadataApi.GetPointersToString(fieldName)
local ResultTable = {}
for k, v in ipairs(fieldNamePoint) do
local classAddress = gg.getValues({{
address = v.address + self.ClassOffset,
flags = Il2cpp.MainType
}})[1].value
if Il2cpp.ClassApi.IsClassInfo(classAddress) then
local result = self.FindFieldInClass(fieldName, classAddress)
table.move(result, 1, #result, #ResultTable + 1, ResultTable)
end
end
assert(type(ResultTable) == "table" and #ResultTable > 0, string.format("The '%s' field is not initialized", fieldName))
return ResultTable
end,
FindFieldWithAddress = function(self, fieldAddress)
local ObjectHead = Il2cpp.ObjectApi.FindHead(fieldAddress)
local fieldOffset = fieldAddress - ObjectHead.address
local classAddress = Il2cpp.FixValue(ObjectHead.value)
local ResultTable = self.FindFieldInClass(fieldOffset, classAddress)
assert(#ResultTable > 0, string.format("nothing was found for this address 0x%X", fieldAddress))
return ResultTable
end,
FindFieldInClass = function(fieldSearchCondition, classAddress)
local ResultTable = {}
local Il2cppClass = Il2cpp.FindClass({
{
Class = classAddress, 
FieldsDump = true
}
})[1]
for i, v in ipairs(Il2cppClass) do
ResultTable[#ResultTable + 1] = type(fieldSearchCondition) == "number" 
and v:GetFieldWithOffset(fieldSearchCondition)
or v:GetFieldWithName(fieldSearchCondition)
end
return ResultTable
end,
FindTypeCheck = {
['string'] = function(self, fieldName)
return Protect:Call(self.FindFieldWithName, self, fieldName)
end,
['number'] = function(self, fieldAddress)
return Protect:Call(self.FindFieldWithAddress, self, fieldAddress)
end,
['default'] = function()
return {
Error = 'Invalid search criteria'
}
end
},
Find = function(self, fieldSearchCondition)
local FieldsInfo = (self.FindTypeCheck[type(fieldSearchCondition)] or self.FindTypeCheck['default'])(self, fieldSearchCondition)
return FieldsInfo
end
}
return FieldApi
end)
__bundle_register("il2cppstruct.globalmetadata", function(require, _LOADED, __bundle_register, __bundle_modules)
local GlobalMetadataApi = {
behaviorForTypes = {
[2] = function(blob)
return Il2cpp.GlobalMetadataApi.ReadNumberConst(blob, gg.TYPE_BYTE)
end,
[3] = function(blob)
return Il2cpp.GlobalMetadataApi.ReadNumberConst(blob, gg.TYPE_BYTE)
end,
[4] = function(blob)
return Il2cpp.GlobalMetadataApi.ReadNumberConst(blob, gg.TYPE_BYTE)
end,
[5] = function(blob)
return Il2cpp.GlobalMetadataApi.ReadNumberConst(blob, gg.TYPE_BYTE)
end,
[6] = function(blob)
return Il2cpp.GlobalMetadataApi.ReadNumberConst(blob, gg.TYPE_WORD)
end,
[7] = function(blob)
return Il2cpp.GlobalMetadataApi.ReadNumberConst(blob, gg.TYPE_WORD)
end,
[8] = function(blob)
local self = Il2cpp.GlobalMetadataApi
return self.version < 29 and self.ReadNumberConst(blob, gg.TYPE_DWORD) or self.ReadCompressedInt32(blob)
end,
[9] = function(blob)
local self = Il2cpp.GlobalMetadataApi
return self.version < 29 and Il2cpp.FixValue(self.ReadNumberConst(blob, gg.TYPE_DWORD)) or self.ReadCompressedUInt32(blob)
end,
[10] = function(blob)
return Il2cpp.GlobalMetadataApi.ReadNumberConst(blob, gg.TYPE_QWORD)
end,
[11] = function(blob)
return Il2cpp.GlobalMetadataApi.ReadNumberConst(blob, gg.TYPE_QWORD)
end,
[12] = function(blob)
return Il2cpp.GlobalMetadataApi.ReadNumberConst(blob, gg.TYPE_FLOAT)
end,
[13] = function(blob)
return Il2cpp.GlobalMetadataApi.ReadNumberConst(blob, gg.TYPE_DOUBLE)
end,
[14] = function(blob)
local self = Il2cpp.GlobalMetadataApi
local length, offset = 0, 0
if self.version >= 29 then
length, offset = self.ReadCompressedInt32(blob)
else
length = self.ReadNumberConst(blob, gg.TYPE_DWORD) 
offset = 4
end
if length ~= -1 then
return Il2cpp.Utf8ToString(blob + offset, length)
end
return ""
end
},
GetStringFromIndex = function(self, index)
local stringDefinitions = Il2cpp.globalMetadataStart + self.stringOffset
return Il2cpp.Utf8ToString(stringDefinitions + index)
end,
GetClassNameFromIndex = function(self, index)
if (self.version < 27) then
local typeDefinitions = Il2cpp.globalMetadataStart + self.typeDefinitionsOffset
index = (self.typeDefinitionsSize * index) + typeDefinitions
else
index = Il2cpp.FixValue(index)
end
local typeDefinition = gg.getValues({{
address = index,
flags = gg.TYPE_DWORD
}})[1].value
return self:GetStringFromIndex(typeDefinition)
end,
GetFieldOrParameterDefalutValue = function(self, dataIndex)
return self.fieldAndParameterDefaultValueDataOffset + Il2cpp.globalMetadataStart + dataIndex
end,
GetIl2CppFieldDefaultValue = function(self, index)
gg.clearResults()
gg.setRanges(0)
gg.setRanges(gg.REGION_C_HEAP | gg.REGION_C_HEAP | gg.REGION_ANONYMOUS | gg.REGION_C_BSS | gg.REGION_C_DATA |
gg.REGION_OTHER | gg.REGION_C_ALLOC)
gg.searchNumber(index, gg.TYPE_DWORD, false, gg.SIGN_EQUAL,
Il2cpp.globalMetadataStart + self.fieldDefaultValuesOffset,
Il2cpp.globalMetadataStart + self.fieldDefaultValuesOffset + self.fieldDefaultValuesSize)
if gg.getResultsCount() > 0 then
local Il2CppFieldDefaultValue = gg.getResults(1)
gg.clearResults()
return Il2CppFieldDefaultValue
end
return {}
end,
ReadCompressedUInt32 = function(Address)
local val, offset = 0, 0
local read = gg.getValues({
{ address = Address, 
flags = gg.TYPE_BYTE
},
{ address = Address + 1, 
flags = gg.TYPE_BYTE
},
{ address = Address + 2, 
flags = gg.TYPE_BYTE
},
{ address = Address + 3, 
flags = gg.TYPE_BYTE
}
})
local read1 = read[1].value & 0xFF
offset = 1
if (read1 & 0x80) == 0 then
val = read1
elseif (read1 & 0xC0) == 0x80 then
val = (read1 & ~0x80) << 8
val = val | (read[2].value & 0xFF)
offset = offset + 1
elseif (read1 & 0xE0) == 0xC0 then
val = (read1 & ~0xC0) << 24
val = val | ((read[2].value & 0xFF) << 16)
val = val | ((read[3].value & 0xFF) << 8)
val = val | (read[4].value & 0xFF)
offset = offset + 3
elseif read1 == 0xF0 then
val = gg.getValues({{address = Address + 1, flags = gg.TYPE_DWORD}})[1].value
offset = offset + 4
elseif read1 == 0xFE then
val = 0xffffffff - 1
elseif read1 == 0xFF then
val = 0xffffffff
end
return val, offset
end,
ReadCompressedInt32 = function(Address)
local encoded, offset = Il2cpp.GlobalMetadataApi.ReadCompressedUInt32(Address)
if encoded == 0xffffffff then
return -2147483647 - 1
end
local isNegative = (encoded & 1) == 1
encoded = encoded >> 1
if isNegative then
return -(encoded + 1)
end
return encoded, offset
end,
ReadNumberConst = function(Address, ggType)
return gg.getValues({{
address = Address,
flags = ggType
}})[1].value
end,
GetDefaultFieldValue = function(self, index)
local Il2CppFieldDefaultValue = self:GetIl2CppFieldDefaultValue(tostring(index))
if #Il2CppFieldDefaultValue > 0 then
local _Il2CppFieldDefaultValue = gg.getValues({
{ address = Il2CppFieldDefaultValue[1].address + 4,
flags = gg.TYPE_DWORD,
},
{ address = Il2CppFieldDefaultValue[1].address + 8,
flags = gg.TYPE_DWORD
}
})
local blob = self:GetFieldOrParameterDefalutValue(_Il2CppFieldDefaultValue[2].value)
local Il2CppType = Il2cpp.MetadataRegistrationApi:GetIl2CppTypeFromIndex(_Il2CppFieldDefaultValue[1].value)
local typeEnum = Il2cpp.TypeApi:GetTypeEnum(Il2CppType)
local behavior = self.behaviorForTypes[typeEnum] or "Not support type"
if type(behavior) == "function" then
return behavior(blob)
end
return behavior
end
return nil
end,
GetPointersToString = function(name)
local pointers = {}
gg.clearResults()
gg.setRanges(0)
gg.setRanges(gg.REGION_C_HEAP | gg.REGION_C_HEAP | gg.REGION_ANONYMOUS | gg.REGION_C_BSS | gg.REGION_C_DATA |
gg.REGION_OTHER | gg.REGION_C_ALLOC)
gg.searchNumber(string.format("Q 00 '%s' 00", name), gg.TYPE_BYTE, false, gg.SIGN_EQUAL,
Il2cpp.globalMetadataStart, Il2cpp.globalMetadataEnd)
gg.searchPointer(0)
pointers = gg.getResults(gg.getResultsCount())
assert(type(pointers) == 'table' and #pointers > 0, string.format("this '%s' is not in the global-metadata", name))
gg.clearResults()
return pointers
end
}
return GlobalMetadataApi
end)
__bundle_register("il2cppstruct.method", function(require, _LOADED, __bundle_register, __bundle_modules)
local AndroidInfo = require("utils.androidinfo")
local Protect = require("utils.protect")
local Il2cppMemory = require("utils.il2cppmemory")
local MethodsApi = {
FindMethodWithName = function(self, MethodName, searchResult)
local FinalMethods = {}
local MethodNamePointers = Il2cpp.GlobalMetadataApi.GetPointersToString(MethodName)
if searchResult.len < #MethodNamePointers then
for methodPointIndex, methodPoint in ipairs(MethodNamePointers) do
methodPoint.address = methodPoint.address - self.NameOffset
local MethodAddress = Il2cpp.FixValue(gg.getValues({methodPoint})[1].value)
if MethodAddress > Il2cpp.il2cppStart and MethodAddress < Il2cpp.il2cppEnd then
FinalMethods[#FinalMethods + 1] = {
MethodName = MethodName,
MethodAddress = MethodAddress,
MethodInfoAddress = methodPoint.address
}
end
end
else
searchResult.isNew = false
end
assert(#FinalMethods > 0, string.format("The '%s' method is not initialized", MethodName))
return FinalMethods
end,
FindMethodWithOffset = function(self, MethodOffset, searchResult)
local MethodsInfo = self:FindMethodWithAddressInMemory(Il2cpp.il2cppStart + MethodOffset, searchResult, MethodOffset)
return MethodsInfo
end,
FindMethodWithAddressInMemory = function(self, MethodAddress, searchResult, MethodOffset)
local RawMethodsInfo = {} gg.clearResults()
gg.setRanges(gg.REGION_C_HEAP | gg.REGION_C_ALLOC | gg.REGION_ANONYMOUS | gg.REGION_C_BSS | gg.REGION_C_DATA |
gg.REGION_OTHER)
if gg.BUILD < 16126 then
gg.searchNumber(string.format("%Xh", MethodAddress), Il2cpp.MainType)
else
gg.loadResults({{
address = MethodAddress,
flags = Il2cpp.MainType
}})
gg.searchPointer(0)
end
local r_count = gg.getResultsCount()
if r_count > searchResult.len then
local r = gg.getResults(r_count)
for j = 1, #r do
RawMethodsInfo[#RawMethodsInfo + 1] = {
MethodAddress = MethodAddress,
MethodInfoAddress = r[j].address,
Offset = MethodOffset
}
end
else
searchResult.isNew = false
end 
gg.clearResults()
assert(#RawMethodsInfo > 0, string.format("nothing was found for this address 0x%X", MethodAddress))
return RawMethodsInfo
end,
DecodeMethodsInfo = function(self, _MethodsInfo, MethodsInfo)
for i = 1, #_MethodsInfo do
local index = (i - 1) * 6
local TypeInfo = Il2cpp.FixValue(MethodsInfo[index + 5].value)
local _TypeInfo = gg.getValues({{ address = TypeInfo + Il2cpp.TypeApi.Type,
flags = gg.TYPE_BYTE
}, { address = TypeInfo,
flags = Il2cpp.MainType
}})
local MethodAddress = Il2cpp.FixValue(MethodsInfo[index + 1].value)
local MethodFlags = MethodsInfo[index + 6].value
_MethodsInfo[i] = {
MethodName = _MethodsInfo[i].MethodName or
Il2cpp.Utf8ToString(Il2cpp.FixValue(MethodsInfo[index + 2].value)),
Offset = string.format("%X", _MethodsInfo[i].Offset or (MethodAddress == 0 and MethodAddress or MethodAddress - Il2cpp.il2cppStart)),
AddressInMemory = string.format("%X", MethodAddress),
MethodInfoAddress = _MethodsInfo[i].MethodInfoAddress,
ClassName = _MethodsInfo[i].ClassName or Il2cpp.ClassApi:GetClassName(MethodsInfo[index + 3].value),
ClassAddress = string.format('%X', Il2cpp.FixValue(MethodsInfo[index + 3].value)),
ParamCount = MethodsInfo[index + 4].value,
ReturnType = Il2cpp.TypeApi:GetTypeName(_TypeInfo[1].value, _TypeInfo[2].value),
IsStatic = (MethodFlags & Il2CppFlags.Method.METHOD_ATTRIBUTE_STATIC) ~= 0,
Access = Il2CppFlags.Method.Access[MethodFlags & Il2CppFlags.Method.METHOD_ATTRIBUTE_MEMBER_ACCESS_MASK] or "",
IsAbstract = (MethodFlags & Il2CppFlags.Method.METHOD_ATTRIBUTE_ABSTRACT) ~= 0,
}
end
end,
UnpackMethodInfo = function(self, MethodInfo)
return {
{ address = MethodInfo.MethodInfoAddress,
flags = Il2cpp.MainType
},
{ address = MethodInfo.MethodInfoAddress + self.NameOffset,
flags = Il2cpp.MainType
},
{ address = MethodInfo.MethodInfoAddress + self.ClassOffset,
flags = Il2cpp.MainType
},
{ address = MethodInfo.MethodInfoAddress + self.ParamCount,
flags = gg.TYPE_BYTE
},
{ address = MethodInfo.MethodInfoAddress + self.ReturnType,
flags = Il2cpp.MainType
},
{ address = MethodInfo.MethodInfoAddress + self.Flags,
flags = gg.TYPE_WORD
}
}, 
{
MethodName = MethodInfo.MethodName or nil,
Offset = MethodInfo.Offset or nil,
MethodInfoAddress = MethodInfo.MethodInfoAddress,
ClassName = MethodInfo.ClassName
}
end,
FindParamsCheck = {
['number'] = function(self, method, searchResult)
if (method > Il2cpp.il2cppStart and method < Il2cpp.il2cppEnd) then
return Protect:Call(self.FindMethodWithAddressInMemory, self, method, searchResult)
else
return Protect:Call(self.FindMethodWithOffset, self, method, searchResult)
end
end,
['string'] = function(self, method, searchResult)
return Protect:Call(self.FindMethodWithName, self, method, searchResult)
end,
['default'] = function()
return {
Error = 'Invalid search criteria'
}
end
},
Find = function(self, method)
local searchResult = Il2cppMemory:GetInformaionOfMethod(method)
if not searchResult then
searchResult = {len = 0}
end
searchResult.isNew = true
local _MethodsInfo = (self.FindParamsCheck[type(method)] or self.FindParamsCheck['default'])(self, method, searchResult)
if searchResult.isNew then
local MethodsInfo = {}
for i = 1, #_MethodsInfo do
local MethodInfo
MethodInfo, _MethodsInfo[i] = self:UnpackMethodInfo(_MethodsInfo[i])
table.move(MethodInfo, 1, #MethodInfo, #MethodsInfo + 1, MethodsInfo)
end
MethodsInfo = gg.getValues(MethodsInfo)
self:DecodeMethodsInfo(_MethodsInfo, MethodsInfo)
searchResult.len = #_MethodsInfo
searchResult.result = _MethodsInfo
Il2cppMemory:SetInformaionOfMethod(method, searchResult)
else
_MethodsInfo = searchResult.result
end
return _MethodsInfo
end
}
return MethodsApi
end)
__bundle_register("il2cppstruct.type", function(require, _LOADED, __bundle_register, __bundle_modules)
local Il2cppMemory = require("utils.il2cppmemory")
local TypeApi = {
tableTypes = {
[1] = "void",
[2] = "bool",
[3] = "char",
[4] = "sbyte",
[5] = "byte",
[6] = "short",
[7] = "ushort",
[8] = "int",
[9] = "uint",
[10] = "long",
[11] = "ulong",
[12] = "float",
[13] = "double",
[14] = "string",
[22] = "TypedReference",
[24] = "IntPtr",
[25] = "UIntPtr",
[28] = "object",
[17] = function(index)
return Il2cpp.GlobalMetadataApi:GetClassNameFromIndex(index)
end,
[18] = function(index)
return Il2cpp.GlobalMetadataApi:GetClassNameFromIndex(index)
end,
[29] = function(index)
local typeMassiv = gg.getValues({
{
address = Il2cpp.FixValue(index),
flags = Il2cpp.MainType
},
{
address = Il2cpp.FixValue(index) + Il2cpp.TypeApi.Type,
flags = gg.TYPE_BYTE
}
})
return Il2cpp.TypeApi:GetTypeName(typeMassiv[2].value, typeMassiv[1].value) .. "[]"
end,
[21] = function(index)
if not (Il2cpp.GlobalMetadataApi.version < 27) then
index = gg.getValues({{
address = Il2cpp.FixValue(index),
flags = Il2cpp.MainType
}})[1].value
end
index = gg.getValues({{
address = Il2cpp.FixValue(index),
flags = Il2cpp.MainType
}})[1].value
return Il2cpp.GlobalMetadataApi:GetClassNameFromIndex(index)
end
},
GetTypeName = function(self, typeIndex, index)
local typeName = self.tableTypes[typeIndex] or string.format('(not support type -> 0x%X)', typeIndex)
if (type(typeName) == 'function') then
local resultType = Il2cppMemory:GetInformationOfType(index)
if not resultType then
resultType = typeName(index)
Il2cppMemory:SetInformationOfType(index, resultType)
end
typeName = resultType
end
return typeName
end,
GetTypeEnum = function(self, Il2CppType)
return gg.getValues({{address = Il2CppType + self.Type, flags = gg.TYPE_BYTE}})[1].value
end
}
return TypeApi
end)
__bundle_register("il2cppstruct.metadataRegistration", function(require, _LOADED, __bundle_register, __bundle_modules)
local Searcher = require("utils.universalsearcher")
local MetadataRegistrationApi = {
GetIl2CppTypeFromIndex = function(self, index)
if not self.metadataRegistration then
self:FindMetadataRegistration()
end
local types = gg.getValues({{address = self.metadataRegistration + self.types, flags = Il2cpp.MainType}})[1].value
return Il2cpp.FixValue(gg.getValues({{address = types + (Il2cpp.pointSize * index), flags = Il2cpp.MainType}})[1].value)
end,
FindMetadataRegistration = function(self)
self.metadataRegistration = Searcher.Il2CppMetadataRegistration()
end
}
return MetadataRegistrationApi
end)
__bundle_register("utils.universalsearcher", function(require, _LOADED, __bundle_register, __bundle_modules)
local AndroidInfo = require("utils.androidinfo")
local Searcher = {
searchWord = ":EnsureCapacity",
FindGlobalMetaData = function(self)
gg.clearResults()
gg.setRanges(gg.REGION_C_HEAP | gg.REGION_C_ALLOC | gg.REGION_ANONYMOUS | gg.REGION_C_BSS | gg.REGION_C_DATA |
gg.REGION_OTHER)
local globalMetadata = gg.getRangesList('global-metadata.dat')
if not self:IsValidData(globalMetadata) then
globalMetadata = {}
gg.clearResults()
gg.searchNumber(self.searchWord, gg.TYPE_BYTE)
gg.refineNumber(self.searchWord:sub(1, 2), gg.TYPE_BYTE)
local EnsureCapacity = gg.getResults(gg.getResultsCount())
gg.clearResults()
for k, v in ipairs(gg.getRangesList()) do
if (v.state == 'Ca' or v.state == 'A' or v.state == 'Cd' or v.state == 'Cb' or v.state == 'Ch' or
v.state == 'O') then
for key, val in ipairs(EnsureCapacity) do
globalMetadata[#globalMetadata + 1] =
(Il2cpp.FixValue(v.start) <= Il2cpp.FixValue(val.address) and Il2cpp.FixValue(val.address) <
Il2cpp.FixValue(v['end'])) and v or nil
end
end
end
end
return globalMetadata[1].start, globalMetadata[#globalMetadata]['end']
end,
IsValidData = function(self, globalMetadata)
if #globalMetadata ~= 0 then
gg.searchNumber(self.searchWord, gg.TYPE_BYTE, false, gg.SIGN_EQUAL, globalMetadata[1].start,
globalMetadata[#globalMetadata]['end'])
if gg.getResultsCount() > 0 then
gg.clearResults()
return true
end
end
return false
end,
FindIl2cpp = function()
local il2cpp = gg.getRangesList(LibNameUnityOnly)
if #il2cpp == 0 then
il2cpp = gg.getRangesList('split_config.')
local _il2cpp = {}
gg.setRanges(gg.REGION_CODE_APP)
for k, v in ipairs(il2cpp) do
if (v.state == 'Xa') then
gg.searchNumber(':il2cpp', gg.TYPE_BYTE, false, gg.SIGN_EQUAL, v.start, v['end'])
if (gg.getResultsCount() > 0) then
_il2cpp[#_il2cpp + 1] = v
gg.clearResults()
end
end
end
il2cpp = _il2cpp
else
local _il2cpp = {}
for k,v in ipairs(il2cpp) do
if (string.find(v.type, "..x.") or v.state == "Xa") then
_il2cpp[#_il2cpp + 1] = v
end
end
il2cpp = _il2cpp
end       
return il2cpp[1].start, il2cpp[#il2cpp]['end']
end,
Il2CppMetadataRegistration = function()
gg.clearResults()
gg.setRanges(gg.REGION_C_HEAP | gg.REGION_C_ALLOC | gg.REGION_ANONYMOUS | gg.REGION_C_BSS | gg.REGION_C_DATA |
gg.REGION_OTHER)
gg.loadResults({{
address = Il2cpp.globalMetadataStart,
flags = Il2cpp.MainType
}})
gg.searchPointer(0)
if gg.getResultsCount() == 0 and AndroidInfo.platform and AndroidInfo.sdk >= 30 then
gg.searchNumber(tostring(Il2cpp.globalMetadataStart | 0xB400000000000000), Il2cpp.MainType)
end
if gg.getResultsCount() > 0 then
local GlobalMetadataPointers, s_GlobalMetadata = gg.getResults(gg.getResultsCount()), 0
for i = 1, #GlobalMetadataPointers do
if i ~= 1 then
local difference = GlobalMetadataPointers[i].address - GlobalMetadataPointers[i - 1].address
if (difference == Il2cpp.pointSize) then
s_GlobalMetadata = Il2cpp.FixValue(gg.getValues({{
address = GlobalMetadataPointers[i].address - (AndroidInfo.platform and 0x10 or 0x8),
flags = Il2cpp.MainType
}})[1].value)
end
end
end
return s_GlobalMetadata
end
return 0
end
}
return Searcher
end)
__bundle_register("utils.patchapi", function(require, _LOADED, __bundle_register, __bundle_modules)
local PatchApi = {
Create = function(self, patchCode)
return setmetatable({
newBytes = patchCode,
oldBytes = gg.getValues(patchCode)
},
{
__index = self,
})
end,
Patch = function(self)
if self.newBytes then
gg.setValues(self.newBytes)
end 
end,
Undo = function(self)
if self.oldBytes then
gg.setValues(self.oldBytes)
end
end,
}
return PatchApi
end)
__bundle_register("utils.version", function(require, _LOADED, __bundle_register, __bundle_modules)
local semver = require("semver.semver")
local VersionEngine = {
ConstSemVer = {
['2018_3'] = semver(2018, 3),
['2019_4_21'] = semver(2019, 4, 21),
['2019_4_15'] = semver(2019, 4, 15),
['2019_3_7'] = semver(2019, 3, 7),
['2020_2_4'] = semver(2020, 2, 4),
['2020_2'] = semver(2020, 2),
['2020_1_11'] = semver(2020, 1, 11),
['2021_2'] = semver(2021, 2)   
},
Year = {
[2017] = function(self, unityVersion)
return 24
end,
[2018] = function(self, unityVersion)
return (not (unityVersion < self.ConstSemVer['2018_3'])) and 24.1 or 24
end,
[2019] = function(self, unityVersion)
local version = 24.2
if not (unityVersion < self.ConstSemVer['2019_4_21']) then
version = 24.5
elseif not (unityVersion < self.ConstSemVer['2019_4_15']) then
version = 24.4
elseif not (unityVersion < self.ConstSemVer['2019_3_7']) then
version = 24.3
end
return version
end,
[2020] = function(self, unityVersion)
local version = 24.3
if not (unityVersion < self.ConstSemVer['2020_2_4']) then
version = 27.1
elseif not (unityVersion < self.ConstSemVer['2020_2']) then
version = 27
elseif not (unityVersion < self.ConstSemVer['2020_1_11']) then
version = 24.4
end
return version
end,
[2021] = function(self, unityVersion)
return (not (unityVersion < self.ConstSemVer['2021_2'])) and 29 or 27.2 
end,
[2022] = function(self, unityVersion)
return 29
end,
},
GetUnityVersion = function()
gg.setRanges(gg.REGION_ANONYMOUS)
gg.clearResults()
gg.searchNumber("00h;32h;30h;0~~0;0~~0;2Eh;0~~0;2Eh::9", gg.TYPE_BYTE, false, gg.SIGN_EQUAL, nil, nil, 1)
local result = gg.getResultsCount() > 0 and gg.getResults(3)[3].address or 0
gg.clearResults()
return result
end,
ReadUnityVersion = function(versionAddress)
local verisonName = Il2cpp.Utf8ToString(versionAddress)
return string.gmatch(verisonName, "(%d+)%p(%d+)%p(%d+)")()
end,
ChooseVersion = function(self, version, globalMetadataHeader)
if not version then
local unityVersionAddress = self.GetUnityVersion()
if unityVersionAddress == 0 then
version = gg.getValues({{address = globalMetadataHeader + 0x4, flags = gg.TYPE_DWORD}})[1].value
else
local p1, p2, p3 = self.ReadUnityVersion(unityVersionAddress)
local unityVersion = semver(tonumber(p1), tonumber(p2), tonumber(p3))
version = self.Year[unityVersion.major] or 29
if type(version) == 'function' then
version = version(self, unityVersion)
end
end
end
local api = assert(Il2CppConst[version], 'Not support this il2cpp version')
Il2cpp.FieldApi.Offset = api.FieldApiOffset
Il2cpp.FieldApi.Type = api.FieldApiType
Il2cpp.FieldApi.ClassOffset = api.FieldApiClassOffset
Il2cpp.ClassApi.NameOffset = api.ClassApiNameOffset
Il2cpp.ClassApi.MethodsStep = api.ClassApiMethodsStep
Il2cpp.ClassApi.CountMethods = api.ClassApiCountMethods
Il2cpp.ClassApi.MethodsLink = api.ClassApiMethodsLink
Il2cpp.ClassApi.FieldsLink = api.ClassApiFieldsLink
Il2cpp.ClassApi.FieldsStep = api.ClassApiFieldsStep
Il2cpp.ClassApi.CountFields = api.ClassApiCountFields
Il2cpp.ClassApi.ParentOffset = api.ClassApiParentOffset
Il2cpp.ClassApi.NameSpaceOffset = api.ClassApiNameSpaceOffset
Il2cpp.ClassApi.StaticFieldDataOffset = api.ClassApiStaticFieldDataOffset
Il2cpp.ClassApi.EnumType = api.ClassApiEnumType
Il2cpp.ClassApi.EnumRsh = api.ClassApiEnumRsh
Il2cpp.ClassApi.TypeMetadataHandle = api.ClassApiTypeMetadataHandle
Il2cpp.ClassApi.InstanceSize = api.ClassApiInstanceSize
Il2cpp.ClassApi.Token = api.ClassApiToken
Il2cpp.MethodsApi.ClassOffset = api.MethodsApiClassOffset
Il2cpp.MethodsApi.NameOffset = api.MethodsApiNameOffset
Il2cpp.MethodsApi.ParamCount = api.MethodsApiParamCount
Il2cpp.MethodsApi.ReturnType = api.MethodsApiReturnType
Il2cpp.MethodsApi.Flags = api.MethodsApiFlags
Il2cpp.GlobalMetadataApi.typeDefinitionsSize = api.typeDefinitionsSize
Il2cpp.GlobalMetadataApi.version = version
local consts = gg.getValues({
{ address = Il2cpp.globalMetadataHeader + api.typeDefinitionsOffset,
flags = gg.TYPE_DWORD
},
{ address = Il2cpp.globalMetadataHeader + api.stringOffset,
flags = gg.TYPE_DWORD,
},
{ address = Il2cpp.globalMetadataHeader + api.fieldDefaultValuesOffset,
flags = gg.TYPE_DWORD,
},
{ address = Il2cpp.globalMetadataHeader + api.fieldDefaultValuesSize,
flags = gg.TYPE_DWORD
},
{ address = Il2cpp.globalMetadataHeader + api.fieldAndParameterDefaultValueDataOffset,
flags = gg.TYPE_DWORD
}
})
Il2cpp.GlobalMetadataApi.typeDefinitionsOffset = consts[1].value
Il2cpp.GlobalMetadataApi.stringOffset = consts[2].value
Il2cpp.GlobalMetadataApi.fieldDefaultValuesOffset = consts[3].value
Il2cpp.GlobalMetadataApi.fieldDefaultValuesSize = consts[4].value
Il2cpp.GlobalMetadataApi.fieldAndParameterDefaultValueDataOffset = consts[5].value
Il2cpp.TypeApi.Type = api.TypeApiType
Il2cpp.Il2CppTypeDefinitionApi.fieldStart = api.Il2CppTypeDefinitionApifieldStart
Il2cpp.MetadataRegistrationApi.types = api.MetadataRegistrationApitypes
end,
}
return VersionEngine
end)
__bundle_register("semver.semver", function(require, _LOADED, __bundle_register, __bundle_modules)
local semver = {
_VERSION     = '1.2.1',
_DESCRIPTION = 'semver for Lua',
_URL         = 'https://github.com/kikito/semver.lua',
_LICENSE     = [[
MIT LICENSE
Copyright (c) 2015 Enrique García Cota
Permission is hereby granted, free of charge, to any person obtaining a
copy of tother software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:
The above copyright notice and tother permission notice shall be included
in all copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
]]
}
local function checkPositiveInteger(number, name)
assert(number >= 0, name .. ' must be a valid positive number')
assert(math.floor(number) == number, name .. ' must be an integer')
end
local function present(value)
return value and value ~= ''
end
local function splitByDot(str)
str = str or ""
local t, count = {}, 0
str:gsub("([^%.]+)", function(c)
count = count + 1
t[count] = c
end)
return t
end
local function parsePrereleaseAndBuildWithSign(str)
local prereleaseWithSign, buildWithSign = str:match("^(-[^+]+)(+.+)$")
if not (prereleaseWithSign and buildWithSign) then
prereleaseWithSign = str:match("^(-.+)$")
buildWithSign      = str:match("^(+.+)$")
end
assert(prereleaseWithSign or buildWithSign, ("The parameter %q must begin with + or - to denote a prerelease or a build"):format(str))
return prereleaseWithSign, buildWithSign
end
local function parsePrerelease(prereleaseWithSign)
if prereleaseWithSign then
local prerelease = prereleaseWithSign:match("^-(%w[%.%w-]*)$")
assert(prerelease, ("The prerelease %q is not a slash followed by alphanumerics, dots and slashes"):format(prereleaseWithSign))
return prerelease
end
end
local function parseBuild(buildWithSign)
if buildWithSign then
local build = buildWithSign:match("^%+(%w[%.%w-]*)$")
assert(build, ("The build %q is not a + sign followed by alphanumerics, dots and slashes"):format(buildWithSign))
return build
end
end
local function parsePrereleaseAndBuild(str)
if not present(str) then return nil, nil end
local prereleaseWithSign, buildWithSign = parsePrereleaseAndBuildWithSign(str)
local prerelease = parsePrerelease(prereleaseWithSign)
local build = parseBuild(buildWithSign)
return prerelease, build
end
local function parseVersion(str)
local sMajor, sMinor, sPatch, sPrereleaseAndBuild = str:match("^(%d+)%.?(%d*)%.?(%d*)(.-)$")
assert(type(sMajor) == 'string', ("Could not extract version number(s) from %q"):format(str))
local major, minor, patch = tonumber(sMajor), tonumber(sMinor), tonumber(sPatch)
local prerelease, build = parsePrereleaseAndBuild(sPrereleaseAndBuild)
return major, minor, patch, prerelease, build
end
local function compare(a,b)
return a == b and 0 or a < b and -1 or 1
end
local function compareIds(myId, otherId)
if myId == otherId then return  0
elseif not myId    then return -1
elseif not otherId then return  1
end
local selfNumber, otherNumber = tonumber(myId), tonumber(otherId)
if selfNumber and otherNumber then return compare(selfNumber, otherNumber)
elseif selfNumber then
return -1
elseif otherNumber then
return 1
else
return compare(myId, otherId) end
end
local function smallerIdList(myIds, otherIds)
local myLength = #myIds
local comparison
for i=1, myLength do
comparison = compareIds(myIds[i], otherIds[i])
if comparison ~= 0 then
return comparison == -1
end
end
return myLength < #otherIds
end
local function smallerPrerelease(mine, other)
if mine == other or not mine then return false
elseif not other then return true
end
return smallerIdList(splitByDot(mine), splitByDot(other))
end
local methods = {}
function methods:nextMajor()
return semver(self.major + 1, 0, 0)
end
function methods:nextMinor()
return semver(self.major, self.minor + 1, 0)
end
function methods:nextPatch()
return semver(self.major, self.minor, self.patch + 1)
end
local mt = { __index = methods }
function mt:__eq(other)
return self.major == other.major and
self.minor == other.minor and
self.patch == other.patch and
self.prerelease == other.prerelease
end
function mt:__lt(other)
if self.major ~= other.major then return self.major < other.major end
if self.minor ~= other.minor then return self.minor < other.minor end
if self.patch ~= other.patch then return self.patch < other.patch end
return smallerPrerelease(self.prerelease, other.prerelease)
end
function mt:__pow(other)
if self.major == 0 then
return self == other
end
return self.major == other.major and
self.minor <= other.minor
end
function mt:__tostring()
local buffer = { ("%d.%d.%d"):format(self.major, self.minor, self.patch) }
if self.prerelease then table.insert(buffer, "-" .. self.prerelease) end
if self.build      then table.insert(buffer, "+" .. self.build) end
return table.concat(buffer)
end
local function new(major, minor, patch, prerelease, build)
assert(major, "At least one parameter is needed")
if type(major) == 'string' then
major,minor,patch,prerelease,build = parseVersion(major)
end
patch = patch or 0
minor = minor or 0
checkPositiveInteger(major, "major")
checkPositiveInteger(minor, "minor")
checkPositiveInteger(patch, "patch")
local result = {major=major, minor=minor, patch=patch, prerelease=prerelease, build=build}
return setmetatable(result, mt)
end
setmetatable(semver, { __call = function(_, ...) return new(...) end })
semver._VERSION= semver(semver._VERSION)
return semver
end)
__bundle_register("utils.il2cppconst", function(require, _LOADED, __bundle_register, __bundle_modules)
local AndroidInfo = require("utils.androidinfo")
Il2CppConst = {
[20] = {
FieldApiOffset = 0xC,
FieldApiType = 0x4,
FieldApiClassOffset = 0x8,
ClassApiNameOffset = 0x8,
ClassApiMethodsStep = 2,
ClassApiCountMethods = 0x9C,
ClassApiMethodsLink = 0x3C,
ClassApiFieldsLink = 0x30,
ClassApiFieldsStep = 0x18,
ClassApiCountFields = 0xA0,
ClassApiParentOffset = 0x24,
ClassApiNameSpaceOffset = 0xC,
ClassApiStaticFieldDataOffset = 0x50,
ClassApiEnumType = 0xB0,
ClassApiEnumRsh = 2,
ClassApiTypeMetadataHandle = 0x2C,
ClassApiInstanceSize = 0x78,
ClassApiToken = 0x98,
MethodsApiClassOffset = 0xC,
MethodsApiNameOffset = 0x8,
MethodsApiParamCount = 0x2E,
MethodsApiReturnType = 0x10,
MethodsApiFlags = 0x28,
typeDefinitionsSize = 0x70,
typeDefinitionsOffset = 0xA0,
stringOffset = 0x18,
fieldDefaultValuesOffset = 0x40,
fieldDefaultValuesSize = 0x44,
fieldAndParameterDefaultValueDataOffset = 0x48,
TypeApiType = 0x6,
Il2CppTypeDefinitionApifieldStart = 0x38,
MetadataRegistrationApitypes = 0x1C,
},
[21] = {
FieldApiOffset = 0xC,
FieldApiType = 0x4,
FieldApiClassOffset = 0x8,
ClassApiNameOffset = 0x8,
ClassApiMethodsStep = 2,
ClassApiCountMethods = 0x9C,
ClassApiMethodsLink = 0x3C,
ClassApiFieldsLink = 0x30,
ClassApiFieldsStep = 0x18,
ClassApiCountFields = 0xA0,
ClassApiParentOffset = 0x24,
ClassApiNameSpaceOffset = 0xC,
ClassApiStaticFieldDataOffset = 0x50,
ClassApiEnumType = 0xB0,
ClassApiEnumRsh = 2,
ClassApiTypeMetadataHandle = 0x2C,
ClassApiInstanceSize = 0x78,
ClassApiToken = 0x98,
MethodsApiClassOffset = 0xC,
MethodsApiNameOffset = 0x8,
MethodsApiParamCount = 0x2E,
MethodsApiReturnType = 0x10,
MethodsApiFlags = 0x28,
typeDefinitionsSize = 0x78,
typeDefinitionsOffset = 0xA0,
stringOffset = 0x18,
fieldDefaultValuesOffset = 0x40,
fieldDefaultValuesSize = 0x44,
fieldAndParameterDefaultValueDataOffset = 0x48,
TypeApiType = 0x6,
Il2CppTypeDefinitionApifieldStart = 0x40,
MetadataRegistrationApitypes = 0x1C,
},
[22] = {
FieldApiOffset = 0xC,
FieldApiType = 0x4,
FieldApiClassOffset = 0x8,
ClassApiNameOffset = 0x8,
ClassApiMethodsStep = 2,
ClassApiCountMethods = 0x94,
ClassApiMethodsLink = 0x3C,
ClassApiFieldsLink = 0x30,
ClassApiFieldsStep = 0x18,
ClassApiCountFields = 0x98,
ClassApiParentOffset = 0x24,
ClassApiNameSpaceOffset = 0xC,
ClassApiStaticFieldDataOffset = 0x4C,
ClassApiEnumType = 0xA9,
ClassApiEnumRsh = 2,
ClassApiTypeMetadataHandle = 0x2C,
ClassApiInstanceSize = 0x70,
ClassApiToken = 0x90,
MethodsApiClassOffset = 0xC,
MethodsApiNameOffset = 0x8,
MethodsApiParamCount = 0x2E,
MethodsApiReturnType = 0x10,
MethodsApiFlags = 0x28,
typeDefinitionsSize = 0x78,
typeDefinitionsOffset = 0xA0,
stringOffset = 0x18,
fieldDefaultValuesOffset = 0x40,
fieldDefaultValuesSize = 0x44,
fieldAndParameterDefaultValueDataOffset = 0x48,
TypeApiType = 0x6,
Il2CppTypeDefinitionApifieldStart = 0x40,
MetadataRegistrationApitypes = 0x1C,
},
[23] = {
FieldApiOffset = 0xC,
FieldApiType = 0x4,
FieldApiClassOffset = 0x8,
ClassApiNameOffset = 0x8,
ClassApiMethodsStep = 2,
ClassApiCountMethods = 0x9C,
ClassApiMethodsLink = 0x40,
ClassApiFieldsLink = 0x34,
ClassApiFieldsStep = 0x18,
ClassApiCountFields = 0xA0,
ClassApiParentOffset = 0x24,
ClassApiNameSpaceOffset = 0xC,
ClassApiStaticFieldDataOffset = 0x50,
ClassApiEnumType = 0xB1,
ClassApiEnumRsh = 2,
ClassApiTypeMetadataHandle = 0x2C,
ClassApiInstanceSize = 0x78,
ClassApiToken = 0x98,
MethodsApiClassOffset = 0xC,
MethodsApiNameOffset = 0x8,
MethodsApiParamCount = 0x2E,
MethodsApiReturnType = 0x10,
MethodsApiFlags = 0x28,
typeDefinitionsSize = 104,
typeDefinitionsOffset = 0xA0,
stringOffset = 0x18,
fieldDefaultValuesOffset = 0x40,
fieldDefaultValuesSize = 0x44,
fieldAndParameterDefaultValueDataOffset = 0x48,
TypeApiType = 0x6,
Il2CppTypeDefinitionApifieldStart = 0x30,
MetadataRegistrationApitypes = 0x1C,
},
[24.1] = {
FieldApiOffset = AndroidInfo.platform and 0x18 or 0xC,
FieldApiType = AndroidInfo.platform and 0x8 or 0x4,
FieldApiClassOffset = AndroidInfo.platform and 0x10 or 0x8,
ClassApiNameOffset = AndroidInfo.platform and 0x10 or 0x8,
ClassApiMethodsStep = AndroidInfo.platform and 3 or 2,
ClassApiCountMethods = AndroidInfo.platform and 0x110 or 0xA8,
ClassApiMethodsLink = AndroidInfo.platform and 0x98 or 0x4C,
ClassApiFieldsLink = AndroidInfo.platform and 0x80 or 0x40,
ClassApiFieldsStep = AndroidInfo.platform and 0x20 or 0x14,
ClassApiCountFields = AndroidInfo.platform and 0x114 or 0xAC,
ClassApiParentOffset = AndroidInfo.platform and 0x58 or 0x2C,
ClassApiNameSpaceOffset = AndroidInfo.platform and 0x18 or 0xC,
ClassApiStaticFieldDataOffset = AndroidInfo.platform and 0xB8 or 0x5C,
ClassApiEnumType = AndroidInfo.platform and 0x126 or 0xBE,
ClassApiEnumRsh = 3,
ClassApiTypeMetadataHandle = AndroidInfo.platform and 0x68 or 0x34,
ClassApiInstanceSize = AndroidInfo.platform and 0xEC or 0x84,
ClassApiToken = AndroidInfo.platform and 0x10c or 0xa4,
MethodsApiClassOffset = AndroidInfo.platform and 0x18 or 0xC,
MethodsApiNameOffset = AndroidInfo.platform and 0x10 or 0x8,
MethodsApiParamCount = AndroidInfo.platform and 0x4A or 0x2A,
MethodsApiReturnType = AndroidInfo.platform and 0x20 or 0x10,
MethodsApiFlags = AndroidInfo.platform and 0x44 or 0x24,
typeDefinitionsSize = 100,
typeDefinitionsOffset = 0xA0,
stringOffset = 0x18,
fieldDefaultValuesOffset = 0x40,
fieldDefaultValuesSize = 0x44,
fieldAndParameterDefaultValueDataOffset = 0x48,
TypeApiType = AndroidInfo.platform and 0xA or 0x6,
Il2CppTypeDefinitionApifieldStart = 0x2C,
MetadataRegistrationApitypes = AndroidInfo.platform and 0x38 or 0x1C,
},
[24] = {
FieldApiOffset = AndroidInfo.platform and 0x18 or 0xC,
FieldApiType = AndroidInfo.platform and 0x8 or 0x4,
FieldApiClassOffset = AndroidInfo.platform and 0x10 or 0x8,
ClassApiNameOffset = AndroidInfo.platform and 0x10 or 0x8,
ClassApiMethodsStep = AndroidInfo.platform and 3 or 2,
ClassApiCountMethods = AndroidInfo.platform and 0x114 or 0xAC,
ClassApiMethodsLink = AndroidInfo.platform and 0x98 or 0x4C,
ClassApiFieldsLink = AndroidInfo.platform and 0x80 or 0x40,
ClassApiFieldsStep = AndroidInfo.platform and 0x28 or 0x18,
ClassApiCountFields = AndroidInfo.platform and 0x118 or 0xB0,
ClassApiParentOffset = AndroidInfo.platform and 0x58 or 0x2C,
ClassApiNameSpaceOffset = AndroidInfo.platform and 0x18 or 0xC,
ClassApiStaticFieldDataOffset = AndroidInfo.platform and 0xB8 or 0x5C,
ClassApiEnumType = AndroidInfo.platform and 0x129 or 0xC1,
ClassApiEnumRsh = 2,
ClassApiTypeMetadataHandle = AndroidInfo.platform and 0x68 or 0x34,
ClassApiInstanceSize = AndroidInfo.platform and 0xF0 or 0x88,
ClassApiToken = AndroidInfo.platform and 0x110 or 0xa8,
MethodsApiClassOffset = AndroidInfo.platform and 0x18 or 0xC,
MethodsApiNameOffset = AndroidInfo.platform and 0x10 or 0x8,
MethodsApiParamCount = AndroidInfo.platform and 0x4E or 0x2E,
MethodsApiReturnType = AndroidInfo.platform and 0x20 or 0x10,
MethodsApiFlags = AndroidInfo.platform and 0x48 or 0x28,
typeDefinitionsSize = 104,
typeDefinitionsOffset = 0xA0,
stringOffset = 0x18,
fieldDefaultValuesOffset = 0x40,
fieldDefaultValuesSize = 0x44,
fieldAndParameterDefaultValueDataOffset = 0x48,
TypeApiType = AndroidInfo.platform and 0xA or 0x6,
Il2CppTypeDefinitionApifieldStart = 0x30,
MetadataRegistrationApitypes = AndroidInfo.platform and 0x38 or 0x1C,
},
[24.2] = {
FieldApiOffset = AndroidInfo.platform and 0x18 or 0xC,
FieldApiType = AndroidInfo.platform and 0x8 or 0x4,
FieldApiClassOffset = AndroidInfo.platform and 0x10 or 0x8,
ClassApiNameOffset = AndroidInfo.platform and 0x10 or 0x8,
ClassApiMethodsStep = AndroidInfo.platform and 3 or 2,
ClassApiCountMethods = AndroidInfo.platform and 0x118 or 0xA4,
ClassApiMethodsLink = AndroidInfo.platform and 0x98 or 0x4C,
ClassApiFieldsLink = AndroidInfo.platform and 0x80 or 0x40,
ClassApiFieldsStep = AndroidInfo.platform and 0x20 or 0x14,
ClassApiCountFields = AndroidInfo.platform and 0x11c or 0xA8,
ClassApiParentOffset = AndroidInfo.platform and 0x58 or 0x2C,
ClassApiNameSpaceOffset = AndroidInfo.platform and 0x18 or 0xC,
ClassApiStaticFieldDataOffset = AndroidInfo.platform and 0xB8 or 0x5C,
ClassApiEnumType = AndroidInfo.platform and 0x12e or 0xBA,
ClassApiEnumRsh = 3,
ClassApiTypeMetadataHandle = AndroidInfo.platform and 0x68 or 0x34,
ClassApiInstanceSize = AndroidInfo.platform and 0xF4 or 0x80,
ClassApiToken = AndroidInfo.platform and 0x114 or 0xa0,
MethodsApiClassOffset = AndroidInfo.platform and 0x18 or 0xC,
MethodsApiNameOffset = AndroidInfo.platform and 0x10 or 0x8,
MethodsApiParamCount = AndroidInfo.platform and 0x4A or 0x2A,
MethodsApiReturnType = AndroidInfo.platform and 0x20 or 0x10,
MethodsApiFlags = AndroidInfo.platform and 0x44 or 0x24,
typeDefinitionsSize = 92,
typeDefinitionsOffset = 0xA0,
stringOffset = 0x18,
fieldDefaultValuesOffset = 0x40,
fieldDefaultValuesSize = 0x44,
fieldAndParameterDefaultValueDataOffset = 0x48,
TypeApiType = AndroidInfo.platform and 0xA or 0x6,
Il2CppTypeDefinitionApifieldStart = 0x24,
MetadataRegistrationApitypes = AndroidInfo.platform and 0x38 or 0x1C,
},
[24.3] = {
FieldApiOffset = AndroidInfo.platform and 0x18 or 0xC,
FieldApiType = AndroidInfo.platform and 0x8 or 0x4,
FieldApiClassOffset = AndroidInfo.platform and 0x10 or 0x8,
ClassApiNameOffset = AndroidInfo.platform and 0x10 or 0x8,
ClassApiMethodsStep = AndroidInfo.platform and 3 or 2,
ClassApiCountMethods = AndroidInfo.platform and 0x118 or 0xA4,
ClassApiMethodsLink = AndroidInfo.platform and 0x98 or 0x4C,
ClassApiFieldsLink = AndroidInfo.platform and 0x80 or 0x40,
ClassApiFieldsStep = AndroidInfo.platform and 0x20 or 0x14,
ClassApiCountFields = AndroidInfo.platform and 0x11c or 0xA8,
ClassApiParentOffset = AndroidInfo.platform and 0x58 or 0x2C,
ClassApiNameSpaceOffset = AndroidInfo.platform and 0x18 or 0xC,
ClassApiStaticFieldDataOffset = AndroidInfo.platform and 0xB8 or 0x5C,
ClassApiEnumType = AndroidInfo.platform and 0x12e or 0xBA,
ClassApiEnumRsh = 3,
ClassApiTypeMetadataHandle = AndroidInfo.platform and 0x68 or 0x34,
ClassApiInstanceSize = AndroidInfo.platform and 0xF4 or 0x80,
ClassApiToken = AndroidInfo.platform and 0x114 or 0xa0,
MethodsApiClassOffset = AndroidInfo.platform and 0x18 or 0xC,
MethodsApiNameOffset = AndroidInfo.platform and 0x10 or 0x8,
MethodsApiParamCount = AndroidInfo.platform and 0x4A or 0x2A,
MethodsApiReturnType = AndroidInfo.platform and 0x20 or 0x10,
MethodsApiFlags = AndroidInfo.platform and 0x44 or 0x24,
typeDefinitionsSize = 92,
typeDefinitionsOffset = 0xA0,
stringOffset = 0x18,
fieldDefaultValuesOffset = 0x40,
fieldDefaultValuesSize = 0x44,
fieldAndParameterDefaultValueDataOffset = 0x48,
TypeApiType = AndroidInfo.platform and 0xA or 0x6,
Il2CppTypeDefinitionApifieldStart = 0x24,
MetadataRegistrationApitypes = AndroidInfo.platform and 0x38 or 0x1C,
},
[24.4] = {
FieldApiOffset = AndroidInfo.platform and 0x18 or 0xC,
FieldApiType = AndroidInfo.platform and 0x8 or 0x4,
FieldApiClassOffset = AndroidInfo.platform and 0x10 or 0x8,
ClassApiNameOffset = AndroidInfo.platform and 0x10 or 0x8,
ClassApiMethodsStep = AndroidInfo.platform and 3 or 2,
ClassApiCountMethods = AndroidInfo.platform and 0x118 or 0xA4,
ClassApiMethodsLink = AndroidInfo.platform and 0x98 or 0x4C,
ClassApiFieldsLink = AndroidInfo.platform and 0x80 or 0x40,
ClassApiFieldsStep = AndroidInfo.platform and 0x20 or 0x14,
ClassApiCountFields = AndroidInfo.platform and 0x11c or 0xA8,
ClassApiParentOffset = AndroidInfo.platform and 0x58 or 0x2C,
ClassApiNameSpaceOffset = AndroidInfo.platform and 0x18 or 0xC,
ClassApiStaticFieldDataOffset = AndroidInfo.platform and 0xB8 or 0x5C,
ClassApiEnumType = AndroidInfo.platform and 0x12e or 0xBA,
ClassApiEnumRsh = 3,
ClassApiTypeMetadataHandle = AndroidInfo.platform and 0x68 or 0x34,
ClassApiInstanceSize = AndroidInfo.platform and 0xF4 or 0x80,
ClassApiToken = AndroidInfo.platform and 0x114 or 0xa0,
MethodsApiClassOffset = AndroidInfo.platform and 0x18 or 0xC,
MethodsApiNameOffset = AndroidInfo.platform and 0x10 or 0x8,
MethodsApiParamCount = AndroidInfo.platform and 0x4A or 0x2A,
MethodsApiReturnType = AndroidInfo.platform and 0x20 or 0x10,
MethodsApiFlags = AndroidInfo.platform and 0x44 or 0x24,
typeDefinitionsSize = 92,
typeDefinitionsOffset = 0xA0,
stringOffset = 0x18,
fieldDefaultValuesOffset = 0x40,
fieldDefaultValuesSize = 0x44,
fieldAndParameterDefaultValueDataOffset = 0x48,
TypeApiType = AndroidInfo.platform and 0xA or 0x6,
Il2CppTypeDefinitionApifieldStart = 0x24,
MetadataRegistrationApitypes = AndroidInfo.platform and 0x38 or 0x1C,
},
[24.5] = {
FieldApiOffset = AndroidInfo.platform and 0x18 or 0xC,
FieldApiType = AndroidInfo.platform and 0x8 or 0x4,
FieldApiClassOffset = AndroidInfo.platform and 0x10 or 0x8,
ClassApiNameOffset = AndroidInfo.platform and 0x10 or 0x8,
ClassApiMethodsStep = AndroidInfo.platform and 3 or 2,
ClassApiCountMethods = AndroidInfo.platform and 0x118 or 0xA4,
ClassApiMethodsLink = AndroidInfo.platform and 0x98 or 0x4C,
ClassApiFieldsLink = AndroidInfo.platform and 0x80 or 0x40,
ClassApiFieldsStep = AndroidInfo.platform and 0x20 or 0x14,
ClassApiCountFields = AndroidInfo.platform and 0x11c or 0xA8,
ClassApiParentOffset = AndroidInfo.platform and 0x58 or 0x2C,
ClassApiNameSpaceOffset = AndroidInfo.platform and 0x18 or 0xC,
ClassApiStaticFieldDataOffset = AndroidInfo.platform and 0xB8 or 0x5C,
ClassApiEnumType = AndroidInfo.platform and 0x12e or 0xBA,
ClassApiEnumRsh = 3,
ClassApiTypeMetadataHandle = AndroidInfo.platform and 0x68 or 0x34,
ClassApiInstanceSize = AndroidInfo.platform and 0xF4 or 0x80,
ClassApiToken = AndroidInfo.platform and 0x114 or 0xa0,
MethodsApiClassOffset = AndroidInfo.platform and 0x18 or 0xC,
MethodsApiNameOffset = AndroidInfo.platform and 0x10 or 0x8,
MethodsApiParamCount = AndroidInfo.platform and 0x4A or 0x2A,
MethodsApiReturnType = AndroidInfo.platform and 0x20 or 0x10,
MethodsApiFlags = AndroidInfo.platform and 0x44 or 0x24,
typeDefinitionsSize = 92,
typeDefinitionsOffset = 0xA0,
stringOffset = 0x18,
fieldDefaultValuesOffset = 0x40,
fieldDefaultValuesSize = 0x44,
fieldAndParameterDefaultValueDataOffset = 0x48,
TypeApiType = AndroidInfo.platform and 0xA or 0x6,
Il2CppTypeDefinitionApifieldStart = 0x24,
MetadataRegistrationApitypes = AndroidInfo.platform and 0x38 or 0x1C,
},
[27] = {
FieldApiOffset = AndroidInfo.platform and 0x18 or 0xC,
FieldApiType = AndroidInfo.platform and 0x8 or 0x4,
FieldApiClassOffset = AndroidInfo.platform and 0x10 or 0x8,
ClassApiNameOffset = AndroidInfo.platform and 0x10 or 0x8,
ClassApiMethodsStep = AndroidInfo.platform and 3 or 2,
ClassApiCountMethods = AndroidInfo.platform and 0x11C or 0xA4,
ClassApiMethodsLink = AndroidInfo.platform and 0x98 or 0x4C,
ClassApiFieldsLink = AndroidInfo.platform and 0x80 or 0x40,
ClassApiFieldsStep = AndroidInfo.platform and 0x20 or 0x14,
ClassApiCountFields = AndroidInfo.platform and 0x120 or 0xA8,
ClassApiParentOffset = AndroidInfo.platform and 0x58 or 0x2C,
ClassApiNameSpaceOffset = AndroidInfo.platform and 0x18 or 0xC,
ClassApiStaticFieldDataOffset = AndroidInfo.platform and 0xB8 or 0x5C,
ClassApiEnumType = AndroidInfo.platform and 0x132 or 0xBA,
ClassApiEnumRsh = 3,
ClassApiTypeMetadataHandle = AndroidInfo.platform and 0x68 or 0x34,
ClassApiInstanceSize = AndroidInfo.platform and 0xF8 or 0x80,
ClassApiToken = AndroidInfo.platform and 0x118 or 0xa0,
MethodsApiClassOffset = AndroidInfo.platform and 0x18 or 0xC,
MethodsApiNameOffset = AndroidInfo.platform and 0x10 or 0x8,
MethodsApiParamCount = AndroidInfo.platform and 0x4A or 0x2A,
MethodsApiReturnType = AndroidInfo.platform and 0x20 or 0x10,
MethodsApiFlags = AndroidInfo.platform and 0x44 or 0x24,
typeDefinitionsSize = 88,
typeDefinitionsOffset = 0xA0,
stringOffset = 0x18,
fieldDefaultValuesOffset = 0x40,
fieldDefaultValuesSize = 0x44,
fieldAndParameterDefaultValueDataOffset = 0x48,
TypeApiType = AndroidInfo.platform and 0xA or 0x6,
Il2CppTypeDefinitionApifieldStart = 0x20,
MetadataRegistrationApitypes = AndroidInfo.platform and 0x38 or 0x1C,
},
[27.1] = {
FieldApiOffset = AndroidInfo.platform and 0x18 or 0xC,
FieldApiType = AndroidInfo.platform and 0x8 or 0x4,
FieldApiClassOffset = AndroidInfo.platform and 0x10 or 0x8,
ClassApiNameOffset = AndroidInfo.platform and 0x10 or 0x8,
ClassApiMethodsStep = AndroidInfo.platform and 3 or 2,
ClassApiCountMethods = AndroidInfo.platform and 0x11C or 0xA4,
ClassApiMethodsLink = AndroidInfo.platform and 0x98 or 0x4C,
ClassApiFieldsLink = AndroidInfo.platform and 0x80 or 0x40,
ClassApiFieldsStep = AndroidInfo.platform and 0x20 or 0x14,
ClassApiCountFields = AndroidInfo.platform and 0x120 or 0xA8,
ClassApiParentOffset = AndroidInfo.platform and 0x58 or 0x2C,
ClassApiNameSpaceOffset = AndroidInfo.platform and 0x18 or 0xC,
ClassApiStaticFieldDataOffset = AndroidInfo.platform and 0xB8 or 0x5C,
ClassApiEnumType = AndroidInfo.platform and 0x132 or 0xBA,
ClassApiEnumRsh = 3,
ClassApiTypeMetadataHandle = AndroidInfo.platform and 0x68 or 0x34,
ClassApiInstanceSize = AndroidInfo.platform and 0xF8 or 0x80,
ClassApiToken = AndroidInfo.platform and 0x118 or 0xa0,
MethodsApiClassOffset = AndroidInfo.platform and 0x18 or 0xC,
MethodsApiNameOffset = AndroidInfo.platform and 0x10 or 0x8,
MethodsApiParamCount = AndroidInfo.platform and 0x4A or 0x2A,
MethodsApiReturnType = AndroidInfo.platform and 0x20 or 0x10,
MethodsApiFlags = AndroidInfo.platform and 0x44 or 0x24,
typeDefinitionsSize = 88,
typeDefinitionsOffset = 0xA0,
stringOffset = 0x18,
fieldDefaultValuesOffset = 0x40,
fieldDefaultValuesSize = 0x44,
fieldAndParameterDefaultValueDataOffset = 0x48,
TypeApiType = AndroidInfo.platform and 0xA or 0x6,
Il2CppTypeDefinitionApifieldStart = 0x20,
MetadataRegistrationApitypes = AndroidInfo.platform and 0x38 or 0x1C,
},
[27.2] = {
FieldApiOffset = AndroidInfo.platform and 0x18 or 0xC,
FieldApiType = AndroidInfo.platform and 0x8 or 0x4,
FieldApiClassOffset = AndroidInfo.platform and 0x10 or 0x8,
ClassApiNameOffset = AndroidInfo.platform and 0x10 or 0x8,
ClassApiMethodsStep = AndroidInfo.platform and 3 or 2,
ClassApiCountMethods = AndroidInfo.platform and 0x11C or 0xA4,
ClassApiMethodsLink = AndroidInfo.platform and 0x98 or 0x4C,
ClassApiFieldsLink = AndroidInfo.platform and 0x80 or 0x40,
ClassApiFieldsStep = AndroidInfo.platform and 0x20 or 0x14,
ClassApiCountFields = AndroidInfo.platform and 0x120 or 0xA8,
ClassApiParentOffset = AndroidInfo.platform and 0x58 or 0x2C,
ClassApiNameSpaceOffset = AndroidInfo.platform and 0x18 or 0xC,
ClassApiStaticFieldDataOffset = AndroidInfo.platform and 0xB8 or 0x5C,
ClassApiEnumType = AndroidInfo.platform and 0x132 or 0xBA,
ClassApiEnumRsh = 2,
ClassApiTypeMetadataHandle = AndroidInfo.platform and 0x68 or 0x34,
ClassApiInstanceSize = AndroidInfo.platform and 0xF8 or 0x80,
ClassApiToken = AndroidInfo.platform and 0x118 or 0xa0,
MethodsApiClassOffset = AndroidInfo.platform and 0x18 or 0xC,
MethodsApiNameOffset = AndroidInfo.platform and 0x10 or 0x8,
MethodsApiParamCount = AndroidInfo.platform and 0x4A or 0x2A,
MethodsApiReturnType = AndroidInfo.platform and 0x20 or 0x10,
MethodsApiFlags = AndroidInfo.platform and 0x44 or 0x24,
typeDefinitionsSize = 88,
typeDefinitionsOffset = 0xA0,
stringOffset = 0x18,
fieldDefaultValuesOffset = 0x40,
fieldDefaultValuesSize = 0x44,
fieldAndParameterDefaultValueDataOffset = 0x48,
TypeApiType = AndroidInfo.platform and 0xA or 0x6,
Il2CppTypeDefinitionApifieldStart = 0x20,
MetadataRegistrationApitypes = AndroidInfo.platform and 0x38 or 0x1C,
},
[29] = {
FieldApiOffset = AndroidInfo.platform and 0x18 or 0xC,
FieldApiType = AndroidInfo.platform and 0x8 or 0x4,
FieldApiClassOffset = AndroidInfo.platform and 0x10 or 0x8,
ClassApiNameOffset = AndroidInfo.platform and 0x10 or 0x8,
ClassApiMethodsStep = AndroidInfo.platform and 3 or 2,
ClassApiCountMethods = AndroidInfo.platform and 0x11C or 0xA4,
ClassApiMethodsLink = AndroidInfo.platform and 0x98 or 0x4C,
ClassApiFieldsLink = AndroidInfo.platform and 0x80 or 0x40,
ClassApiFieldsStep = AndroidInfo.platform and 0x20 or 0x14,
ClassApiCountFields = AndroidInfo.platform and 0x120 or 0xA8,
ClassApiParentOffset = AndroidInfo.platform and 0x58 or 0x2C,
ClassApiNameSpaceOffset = AndroidInfo.platform and 0x18 or 0xC,
ClassApiStaticFieldDataOffset = AndroidInfo.platform and 0xB8 or 0x5C,
ClassApiEnumType = AndroidInfo.platform and 0x132 or 0xBA,
ClassApiEnumRsh = 2,
ClassApiTypeMetadataHandle = AndroidInfo.platform and 0x68 or 0x34,
ClassApiInstanceSize = AndroidInfo.platform and 0xF8 or 0x80,
ClassApiToken = AndroidInfo.platform and 0x118 or 0xa0,
MethodsApiClassOffset = AndroidInfo.platform and 0x20 or 0x10,
MethodsApiNameOffset = AndroidInfo.platform and 0x18 or 0xC,
MethodsApiParamCount = AndroidInfo.platform and 0x52 or 0x2E,
MethodsApiReturnType = AndroidInfo.platform and 0x28 or 0x14,
MethodsApiFlags = AndroidInfo.platform and 0x4C or 0x28,
typeDefinitionsSize = 88,
typeDefinitionsOffset = 0xA0,
stringOffset = 0x18,
fieldDefaultValuesOffset = 0x40,
fieldDefaultValuesSize = 0x44,
fieldAndParameterDefaultValueDataOffset = 0x48,
TypeApiType = AndroidInfo.platform and 0xA or 0x6,
Il2CppTypeDefinitionApifieldStart = 0x20,
MetadataRegistrationApitypes = AndroidInfo.platform and 0x38 or 0x1C,
}
}
Il2CppFlags = {
Method = {
METHOD_ATTRIBUTE_MEMBER_ACCESS_MASK = 0x0007,
Access = {
"private", "internal", "internal", "protected", "protected internal", "public", },
METHOD_ATTRIBUTE_STATIC = 0x0010,
METHOD_ATTRIBUTE_ABSTRACT = 0x0400,
},
Field = {
FIELD_ATTRIBUTE_FIELD_ACCESS_MASK = 0x0007,
Access = {
"private", "internal", "internal", "protected", "protected internal", "public", },
FIELD_ATTRIBUTE_STATIC = 0x0010,
FIELD_ATTRIBUTE_LITERAL = 0x0040,
}
}
end)
return __bundle_require("GGIl2cpp")
