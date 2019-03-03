stock const char API_KEY[] = "81d0f7e3b9d61d19209fe713232177ba";
stock const char URL[] = "http://stats.tibari.ru/api/v1/add_server";

/* Stats pusher */
public int SteamWorks_SteamServersConnected()
{
    Handle plugin = GetMyHandle();
    if (GetPluginStatus(plugin) == Plugin_Running)
    {
        char cBuffer[256], cVersion[12];
        GetPluginInfo(plugin, PlInfo_Version, cVersion, sizeof(cVersion));
        FormatEx(cBuffer, sizeof(cBuffer), "%s", URL);
        Handle hndl = SteamWorks_CreateHTTPRequest(k_EHTTPMethodPOST, cBuffer);
        FormatEx(cBuffer, sizeof(cBuffer), "key=%s&ip=%s&port=%d&version=%s", API_KEY, g_sAddress, g_iPort, cVersion);
        SteamWorks_SetHTTPRequestRawPostBody(hndl, "application/x-www-form-urlencoded", cBuffer, sizeof(cBuffer));
        SteamWorks_SetHTTPCallbacks(hndl, SteamWorks_OnTransferComplete);
        SteamWorks_SendHTTPRequest(hndl);
        delete hndl;
    }
}

public int SteamWorks_OnTransferComplete(Handle hRequest, bool bFailure, bool bRequestSuccessful, EHTTPStatusCode eStatusCode) {
    //delete hRequest;
    switch(eStatusCode) {
        case k_EHTTPStatusCode200OK:                    LogAction(-1, -1, "[WarnSystem] Server successfully added/refreshed");
        case k_EHTTPStatusCode400BadRequest:            LogWarnings("[WarnSystem] Bad request");
        case k_EHTTPStatusCode403Forbidden:             LogWarnings("[WarnSystem] IP:Port is incorrect");
        case k_EHTTPStatusCode404NotFound:              LogWarnings("[WarnSystem] Server or version doesn't exists");
        case k_EHTTPStatusCode406NotAcceptable:         LogWarnings("[WarnSystem] APIKEY is incorrect");
        case k_EHTTPStatusCode413RequestEntityTooLarge: LogWarnings("[WarnSystem] Request Entity Too Large");
    }
}
