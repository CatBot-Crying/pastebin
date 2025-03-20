local client = function()
Variable = {}
Variable["LoginURL"]= "http://saki-cheat.x10.mx/..__Lo__g__in_.php"
Variable["LoginURL"] = (function() return {Variable["LoginURL"]} end)()
Prompt = gg.prompt({"🔑 ᴘᴀssᴡᴏʀᴅ","❌ ᴇxɪᴛ"},nil,{"text","checkbox"})
 if not Prompt or Prompt[1] == "" then return print("✝️┇ ɪɴᴠᴀʟɪᴅ ᴘᴀssᴡᴏʀᴅ") end
 if Prompt[2] then return end
  Prompt[1] = Prompt[1]:gsub("[ ]",""):gsub("[\n]", "")
Variable["TempLogin"]  = "key="..Prompt[1]..""
Variable["TempLogin"] = (function(...) return {Variable["TempLogin"]} end)()
ResponseContent = gg.makeRequest(Variable["LoginURL"][1],nil,Variable["TempLogin"][1]).content
if not ResponseContent then return print("📲 ᴘʟᴇᴀꜱᴇ ᴄʜᴇᴄᴋ ʏᴏᴜʀ ɪɴᴛᴇʀɴᴇᴛ ᴄᴏɴɴᴇᴄᴛɪᴏɴ\n🎡 ᴏʀ ᴛʀʏ ᴀɢᴀɪɴ") end
pcall(load(ResponseContent)) end

gg.setVisible(false)
json = load(gg.makeRequest("https://raw.githubusercontent.com/CatBot-Crying/pastebin/refs/heads/main/json.lua").content)()

local ipAddress = gg.makeRequest('http://checkip.dyndns.org/').content:match("%d+%.%d+%.%d+%.%d+")

if ipAddress then
    local vpnData = json.decode(gg.makeRequest('http://v2.api.iphub.info/ip/' .. ipAddress, {
        ['X-Key'] = "MjcyODk6QXZzMkhYczBiakFwSVlJUkZ6bkpodlM1V1NiQ1BZWEE="
    }).content)

    if vpnData and vpnData.block == 1 then
        while true do gg.alert("⚠️ VPN Or Proxy Detected ⚠️ \n\n🔒 Reject IP Address :" .. ipAddress .. "","Exit") break end
    else
        gg.alert("🟢 No VPN Or Proxy Detected 🟢\n\n🔓 Accept IP Address : " .. ipAddress .. "","close");client()
    end
else
    gg.alert("⚠️ IP Address Could Not Be Parsed ⚠️")
end
