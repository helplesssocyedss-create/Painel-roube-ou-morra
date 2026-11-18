
-- ROUBE OU MORRA - TESTE DE ENVIO V16
-- Feito por Tales
-- Teste de conexão com o Admin Supabase

local HttpService = game:GetService("HttpService")

local SUPABASE_URL = "https://nqafhfadocgqkzboyxpp.supabase.co"
local COLLECTOR_TOKEN = "RBjAv5gAQ0QBuef0ue3wrhERLlMAuaumDJ0GnAHq83M"

local endpoint = SUPABASE_URL .. "/functions/v1/ingest-report"

local sendRequest =
    (type(request) == "function" and request)
    or (type(http_request) == "function" and http_request)
    or (type(syn) == "table" and syn.request)

if not sendRequest then
    warn("[Tales] Executor sem suporte à função request.")
    return
end

local sessionId = HttpService:GenerateGUID(false)

local report = {
    session_id = sessionId,
    record_key = "teste-conexao-" .. sessionId,
    payload = {
        Name = "TESTE DE CONEXAO",
        Class = "DiagnosticReport",
        Path = "RoubeOuMorra/Admin/ConnectivityTest",
        Message = "Roblox conseguiu enviar dados ao Supabase.",
        Version = "V16",
        Author = "Tales",
        Timestamp = os.date("%Y-%m-%d %H:%M:%S")
    }
}

local success, response = pcall(function()
    return sendRequest({
        Url = endpoint,
        Method = "POST",
        Headers = {
            ["Content-Type"] = "application/json",
            ["x-collector-token"] = COLLECTOR_TOKEN
        },
        Body = HttpService:JSONEncode(report)
    })
end)

if not success then
    warn("[Tales] Falha no envio:", response)
    return
end

local status = response.StatusCode or response.Status or 0
print("[Tales] Resposta HTTP:", status)
print("[Tales] Resposta:", response.Body or "")

if status >= 200 and status < 300 then
    print("[Tales] RELATORIO ENVIADO COM SUCESSO!")
else
    warn("[Tales] O SERVIDOR RECUSOU O ENVIO.")
end
