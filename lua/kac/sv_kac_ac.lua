
print("[KAC] \tLoaded sv_kac_ac.lua")

local AntiAimbotCVAR = CreateConVar("sv_kac_enforce_aimbot", 1, 128, "Enables Anti-Cheat Aimbot AutoBan", 0, 1)

local function difference(A, B)
    if not A or not B then return 0 end
    if math.max(A,B) == B then
        return B - A
    else
        return A - B
    end
end

local function subT(A, B)
    if not A or not B then return 0 end
    Diff = ((A - B) + 180) % 360 - 180
    if Diff < 180 then return Diff end
    return Diff - 360
end

local function roundVec(Vec, dec)
    if not Vec then return Vector() end
    dec = dec or 0
    return Vector(math.Truncate(Vec[1],dec),math.Truncate(Vec[2],dec),math.Truncate(Vec[3],dec))
end
local function roundAng(Ang, dec)
    if not Ang then return Angle() end
    dec = dec or 0
    return Angle(math.Truncate(Ang[1],dec),math.Truncate(Ang[2],dec),math.Truncate(Ang[3],dec))
end

local function inRange(num, min, max)
    return num >= min and num <= max
end

hook.Add("StartCommand", "KAC_Movement", function(ply, ucmd)
    if not ply then return end
    if ply:IsBot() then return end

    local steamC = KAC.returnData(ply)
    if KAC[steamC] then

        if ucmd:IsForced() then
            KAC[steamC].syncedCurtime = -1
            --KAC.debug("[KAC] Anti-Cheat: " .. ply:Name() .. " forced ucmd")
        end
        if KAC.isDesynced(ply) then
            KAC.UpdateData(ply, false, 0.5)
            --KAC.debug("[KAC] Anti-Cheat: " .. ply:Name() .. " desynced")
            return
        end

        local Systime = SysTime()
        local StillLock = false
        local Run = KAC.UpdateData(ply)

        if ply:GetMoveType() != KAC[steamC].moveCheck then
            KAC[steamC].moveCheck = ply:GetMoveType()
        elseif Run then
            local Weapon = ply:GetActiveWeapon()

            if KAC[steamC].groundCheck < 5 then
                local Want = roundAng(ucmd:GetViewAngles(),2)
                local Last = roundAng(KAC[steamC].eyea,2)

                if Want != Angle() and Last != Angle() and Want != Last and ucmd:GetMouseX() == 0 and ucmd:GetMouseY() == 0 and KAC[steamC].xboxcontroller < Systime then

                    local P = math.Truncate(subT(Want.p,Last.p),2)
                    local Y = math.Truncate(subT(Want.y,Last.y),2)

                    --print(P,Y,ucmd:GetMouseX(),ucmd:GetMouseY())

                    local AP = math.abs(P)
                    local AY = math.abs(Y)

                    if IsValid(Weapon) and (AP > 1 or AY > 1) and P != KAC[steamC].deltaData[1] and Y != KAC[steamC].deltaData[2] and KAC[steamC].weaponData.deathTime + 1 < CurTime() then

                        local P2 = math.Truncate(subT(KAC[steamC].deltaData[1],P),2)
                        local Y2 = math.Truncate(subT(KAC[steamC].deltaData[2],Y),2)

                        math.randomseed(math.random(1,Systime))

                        if KAC[steamC].spreadData != Vector() and KAC[steamC].spreadData[3] + 1 > Systime then
                            if AP + AY > 15 and inRange(P * -1,KAC[steamC].spreadData[1] - 2,KAC[steamC].spreadData[1] + 2) and inRange(Y * -1,KAC[steamC].spreadData[2] - 2,KAC[steamC].spreadData[2] + 2) then
                                KAC.printClient(ply:UserID(), -1, "Anti-Cheat# Silent Aim")
                                if AntiAimbotCVAR:GetInt() == 1 then KAC.pushTrigger(ply, "aimbot", 1) end
                                KAC[steamC].spreadData = Vector()
                            end
                        end

                        if KAC[steamC].lockData[1] == 0 and not KAC[steamC].mouseCheck then
                            if KAC[steamC].shotCooldown != 0 and KAC[steamC].shotCooldown <= Systime then
                                --KAC.debug("[KAC] Trace: " .. ply:Name() .. " [" .. P .. "," .. Y .. "] " .. tostring(Weapon))

                                local St = ply:GetShootPos()
                                local Dir = ucmd:GetViewAngles():Forward()
                                local Ray = ents.FindAlongRay(St + Dir * 100, St + Dir * 10000, Vector(-10,-10,-10), Vector(10,10,10))
                                local Ent = nil

                                if #Ray > 0 then
                                    for _,e in ipairs(Ray) do
                                        if Ent == nil then
                                            if e != ply and e:GetClass() == "player" then
                                                Ent = e
                                            end
                                        end
                                    end
                                end

                                if IsValid(Ent) then
                                    KAC[steamC].lockData = Vector(Systime,Systime,math.max(math.abs(P),math.abs(Y)))
                                    KAC[steamC].spreadData = Vector(P,Y,Systime)
                                end
                            end
                        end
                    end

                    StillLock = true
                    KAC[steamC].lockData[2] = Systime
                    KAC[steamC].deltaData[1] = P
                    KAC[steamC].deltaData[2] = Y
                else
                    KAC[steamC].deltaData = Vector()
                    KAC[steamC].spreadData = Vector()
                end

                if not ply:IsOnGround() and KAC[steamC].button.jump == 1 then
                    KAC[steamC].groundCheck = 1
                else 
                    KAC[steamC].groundCheck = 0
                end

                if KAC[steamC].button.duck == 1 then
                    if KAC[steamC].button.jump == 1 then
                        if Systime - KAC[steamC].jumpData[3] < 0.5 then
                            KAC[steamC].jumpData[3] = Systime + 1
                        end
                    elseif not ply:IsOnGround() then
                        if KAC[steamC].jumpData[3] > Systime then
                            local Vel = ply:GetVelocity()
                            if ( math.abs(math.Truncate(Vel[1])) + math.abs(math.Truncate(Vel[2])) ) > 150 then
                                if difference(Vel[1],KAC[steamC].jumpData[1]) >= 250 or difference(Vel[2],KAC[steamC].jumpData[2]) >= 250 then
                                    ucmd:ClearMovement()
                                    Vel[3] = 0
                                    ply:SetVelocity(-Vel)
                                    KAC.debug("[KAC] Anti-Cheat: " .. ply:Name() .. ": blocked side-hop")
                                end
                            end
                        end
                        KAC[steamC].jumpData = ply:GetVelocity()
                        KAC[steamC].jumpData[3] = Systime
                    end
                else
                    KAC[steamC].jumpData = Vector()
                end
            else
                KAC[steamC].deltaData = Vector()
                KAC[steamC].spreadData = Vector()
            end
        end

        if KAC[steamC].lockData[1] != 0 then
            if StillLock == true then
            else
                if KAC[steamC].lockData[2] >= KAC[steamC].lockData[1] then
                    local Time = math.Truncate(KAC[steamC].lockData[2] - KAC[steamC].lockData[1],2)
                    if Time < 0.05 then
                        KAC.printClient(ply:UserID(), -1, "Anti-Cheat# Snap [" .. math.Truncate(KAC[steamC].lockData[3],2) .. "°]")
                        if AntiAimbotCVAR:GetInt() == 1 then KAC.pushTrigger(ply, "aimbot", 0.5) end
                    else
                        KAC.printClient(ply:UserID(), -1, "Anti-Cheat# Aimlock [" .. math.Truncate(KAC[steamC].lockData[3],2) .. "°][" .. Time .. "sec]")
                        if AntiAimbotCVAR:GetInt() == 1 then KAC.pushTrigger(ply, "aimbot", 1) end
                    end
                end
                KAC[steamC].lockData = Vector()
            end
        end

        if KAC[steamC].groundCheck > 5 and KAC[steamC].groundCheck < Systime then KAC[steamC].groundCheck = 0 end

        KAC[steamC].mouseCheck = ucmd:GetMouseX() != 0 or ucmd:GetMouseY() != 0
        KAC[steamC].eyea = ucmd:GetViewAngles()
    end
end)

hook.Add("OnPlayerHitGround", "KAC_Ground", function(ply, inWater, onFloater, speed)
    if not ply or inWater or onFloater then return end

    local steamC = KAC.returnData(ply)
    if KAC[steamC] then
        if not KAC.UpdateData(ply) then return end

        if KAC[steamC].groundCheck == 1 and not KAC.isDesynced(ply) then
            if KAC[steamC].button.jump == 1 then
                timer.Simple(0, function()
                    if ply:IsOnGround() or not KAC.UpdateData(ply) or KAC[steamC].button.jump == -1 or KAC.isDesynced(ply) then return end

                    local vel = ply:GetVelocity()
                    if (math.abs(math.Truncate(vel[1])) + math.abs(math.Truncate(vel[2]))) <= 300 or math.Truncate(vel[3]) < 50 then return end

                    KAC.printClient(ply:UserID(), -1, "Anti-Cheat# Detected BHOP Scripts")
                    KAC.pushTrigger(ply, "bhop", 1)
                end)
            end
        end
    end
end)

hook.Add("EntityFireBullets", "KAC_Bullet", function(ent, dataTab)
    if dataTab["Num"] > 1 or dataTab["Force"] < 1 then return end
    if dataTab["Distance"] < 1000 then return end
    if dataTab["IgnoreEntity"]:IsWorld() then return end
    if dataTab["Tracer"] == "" or dataTab["Tracer"] == nil or dataTab["TracerName"] == "m9k_effect_mad_penetration_trace" then return end
    local ply = dataTab["Attacker"]
    if not IsValid(ply) then return end
    local steamC = KAC.returnData(ply)
    if KAC[steamC] then
        KAC[steamC].shotCooldown = 0
        if ply:Alive() then
            local weapon = ply:GetActiveWeapon()
            if IsValid(weapon) then
                if KAC[steamC].button["attack"] != 1 then
                    KAC.pushTrigger(ply, "autoshoot", 5)
                end
                local clamp = 0
                if dataTab["Num"] == 1 then
                    clamp = math.Clamp(dataTab["Damage"] / 150, 1, 150)
                end
                KAC[steamC].shotCooldown = SysTime() + 0.25 + (dataTab["Num"] * 0.05) + clamp

                local context = ply:GetEyeTrace()
                local no_context = ply:GetEyeTraceNoCursor()
                if context["Normal"] != no_context["Normal"] then
                    if not ply:GetNWBool("KAC_ContextMenu", true) then
                        local context_angle = context["Normal"]:Angle()
                        local no_context_angle = no_context["Normal"]:Angle()

                        local P = math.Truncate(subT(context_angle.p,no_context_angle.p),2)
                        local Y = math.Truncate(subT(context_angle.y,no_context_angle.y),2)

                        if math.abs(P) > 15 or math.abs(Y) > 15 then
                            KAC.debug("[KAC] Anti-Cheat: " .. ply:Name() .. ": context difference P[" .. P .. "] Y[" .. Y .. "], Silent Aimbot?")
                        end
                    end
                end
            end
        end
    end
end)

local exploit_nets = {
    "pplay_deleterow",
    "pplay_addrow",
    "pplay_sendtable",
    "WriteQuery",
    "SendMoney",
    "BailOut",
    "customprinter_get",
    "textstickers_entdata",
    "NC_GetNameChange",
    "ATS_WARP_REMOVE_CLIENT",
    "ATS_WARP_FROM_CLIENT",
    "ATS_WARP_VIEWOWNER",
    "CFRemoveGame",
    "CFJoinGame",
    "CFEndGame",
    "CreateCase",
    "rprotect_terminal_settings",
    "StackGhost",
    "RevivePlayer",
    "ARMORY_RetrieveWeapon",
    "TransferReport",
    "SimplicityAC_aysent",
    "pac_to_contraption",
    "SyncPrinterButtons76561198056171650",
    "sendtable",
    "steamid2",
    "Kun_SellDrug",
    "net_PSUnBoxServer",
    "pplay_deleterow",
    "pplay_addrow",
    "CraftSomething",
    "banleaver",
    "75_plus_win",
    "ATMDepositMoney",
    "Taxi_Add",
    "Kun_SellOil",
    "SellMinerals",
    "TakeBetMoney",
    "PoliceJoin",
    "CpForm_Answers",
    "DepositMoney",
    "MDE_RemoveStuff_C2S",
    "NET_SS_DoBuyTakeoff",
    "NET_EcSetTax",
    "RP_Accept_Fine",
    "RP_Fine_Player",
    "RXCAR_Shop_Store_C2S",
    "RXCAR_SellINVCar_C2S",
    "drugseffect_remove",
    "drugs_money",
    "CRAFTINGMOD_SHOP",
    "drugs_ignite",
    "drugseffect_hpremove",
    "DarkRP_Kun_ForceSpawn",
    "drugs_text",
    "NLRKick",
    "RecKickAFKer",
    "GMBG:PickupItem",
    "DL_Answering",
    "data_check",
    "plyWarning",
    "NLR.ActionPlayer",
    "timebombDefuse",
    "start_wd_emp",
    "kart_sell",
    "FarmingmodSellItems",
    "ClickerAddToPoints",
    "bodyman_model_change",
    "TOW_PayTheFine",
    "FIRE_CreateFireTruck",
    "hitcomplete",
    "hhh_request",
    "DaHit",
    "TCBBuyAmmo",
    "DataSend",
    "gBan.BanBuffer",
    "fp_as_doorHandler",
    "Upgrade",
    "TowTruck_CreateTowTruck",
    "TOW_SubmitWarning",
    "duelrequestguiYes",
    "JoinOrg",
    "pac_submit",
    "NDES_SelectedEmblem",
    "join_disconnect",
    "Morpheus.StaffTracker",
    "casinokit_chipexchange",
    "BuyKey",
    "BuyCrate",
    "FactionInviteConsole",
    "FacCreate",
    "1942_Fuhrer_SubmitCandidacy",
    "pogcp_report_submitReport",
    "textscreens_download",
    "hsend",
    "BuilderXToggleKill",
    "Chatbox_PlayerChat",
    "reports.submit",
    "services_accept",
    "Warn_CreateWarn",
    "NewReport",
    "soez",
    "GiveHealthNPC",
    "DarkRP_SS_Gamble",
    "buyinghealth",
    "DarkRP_preferredjobmodel",
    "whk_setart",
    "WithdrewBMoney",
    "DuelMessageReturn",
    "ban_rdm",
    "BuyCar",
    "ats_send_toServer",
    "dLogsGetCommand",
    "disguise",
    "gportal_rpname_change",
    "AbilityUse",
    "ClickerAddToPoints",
    "race_accept",
    "give_me_weapon",
    "FinishContract",
    "NLR_SPAWN",
    "Kun_ZiptieStruggle",
    "JB_Votekick",
    "Letthisdudeout",
    "ckit_roul_bet",
    "pac.net.TouchFlexes.ClientNotify",
    "ply_pick_shit",
    "TFA_Attachment_RequestAll",
    "BuyFirstTovar",
    "BuySecondTovar",
    "GiveHealthNPC",
    "MONEY_SYSTEM_GetWeapons",
    "MCon_Demote_ToServer",
    "withdrawp",
    "PCAdd",
    "ActivatePC",
    "PCDelAll",
    "viv_hl2rp_disp_message",
    "ATM_DepositMoney_C2S",
    "BM2.Command.SellBitcoins",
    "BM2.Command.Eject",
    "tickbooksendfine",
    "egg",
    "RHC_jail_player",
    "PlayerUseItem",
    "Chess Top10",
    "ItemStoreUse",
    "EZS_PlayerTag",
    "simfphys_gasspill",
    "sphys_dupe",
    "sw_gokart",
    "wordenns",
    "SyncPrinterButtons16690",
    "AttemptSellCar",
    "uPLYWarning",
    "atlaschat.rqclrcfg",
    "dlib.getinfo.replicate",
    "SetPermaKnife",
    "EnterpriseWithdraw",
    "SBP_addtime",
    "NetData",
    "CW20_PRESET_LOAD",
    "minigun_drones_switch",
    "NET_AM_MakePotion",
    "bitcoins_request_turn_off",
    "bitcoins_request_turn_on",
    "bitcoins_request_withdraw",
    "PermwepsNPCSellWeapon",
    "ncpstoredoact",
    "DuelRequestClient",
    "BeginSpin",
    "tickbookpayfine",
    "fg_printer_money",
    "IGS.GetPaymentURL",
    "pp_info_send",
    "AirDrops_StartPlacement",
    "SlotsRemoved",
    "FARMINGMOD_DROPITEM",
    "cab_sendmessage",
    "cab_cd_testdrive",
    "blueatm",
    "SCP-294Sv",
    "dronesrewrite_controldr",
    "desktopPrinter_Withdraw",
    "RemoveTag",
    "IDInv_RequestBank",
    "UseMedkit",
    "WipeMask",
    "SwapFilter",
    "RemoveMask",
    "DeployMask",
    "ZED_SpawnCar",
    "levelup_useperk",
    "passmayorexam",
    "Selldatride",
    "ORG_VaultDonate",
    "ORG_NewOrg",
    "ScannerMenu",
    "misswd_accept",
    "D3A_Message",
    "LawsToServer",
    "Shop_buy",
    "D3A_CreateOrg",
    "Gb_gasstation_BuyGas",
    "Gb_gasstation_BuyJerrycan",
    "MineServer",
    "AcceptBailOffer",
    "LawyerOfferBail",
    "buy_bundle",
    "AskPickupItemInv",
    "donatorshop_itemtobuy",
    "netOrgVoteInvite_Server",
    "Chess ClientWager",
    "AcceptRequest",
    "deposit",
    "CubeRiot CaptureZone Update",
    "NPCShop_BuyItem",
    "SpawnProtection",
    "hoverboardpurchase",
    "soundArrestCommit",
    "LotteryMenu",
    "updateLaws",
    "TMC_NET_FirePlayer",
    "thiefnpc",
    "TMC_NET_MakePlayerWanted",
    "SyncRemoveAction",
    "HV_AmmoBuy",
    "NET_CR_TakeStoredMoney",
    "nox_addpremadepunishment",
    "GrabMoney",
    "LAWYER.GetBailOut",
    "LAWYER.BailFelonOut",
    "br_send_pm",
    "GET_Admin_MSGS",
    "OPEN_ADMIN_CHAT",
    "LB_AddBan",
    "redirectMsg",
    "RDMReason_Explain",
    "JB_SelectWarden",
    "JB_GiveCubics",
    "SendSteamID",
    "wyozimc_playply",
    "SpecDM_SendLoadout",
    "sv_saveweapons",
    "DL_StartReport",
    "DL_ReportPlayer",
    "DL_AskLogsList",
    "DailyLoginClaim",
    "GiveWeapon",
    "GovStation_SpawnVehicle",
    "inviteToOrganization",
    "createFaction",
    "sellitem",
    "giveArrestReason",
    "unarrestPerson",
    "JoinFirstSS",
    "bringNfreeze",
    "start_wd_hack",
    "DestroyTable",
    "nCTieUpStart",
    "IveBeenRDMed",
    "FIGHTCLUB_StartFight",
    "FIGHTCLUB_KickPlayer",
    "ReSpawn",
    "CP_Test_Results",
    "AcceptBailOffer",
    "IS_SubmitSID_C2S",
    "IS_GetReward_C2S",
    "ChangeOrgName",
    "DisbandOrganization",
    "CreateOrganization",
    "newTerritory",
    "InviteMember",
    "sendDuelInfo",
    "DoDealerDeliver",
    "PurchaseWeed",
    "guncraft_removeWorkbench",
    "wordenns",
    "userAcceptPrestige",
    "vj_npcspawner_sv_create",
    "DuelMessageReturn",
    "Client_To_Server_OpenEditor",
    "GiveSCP294Cup",
    "GiveArmor100",
    "SprintSpeedset",
    "ArmorButton",
    "HealButton",
    "SRequest",
    "ClickerForceSave",
    "rpi_trade_end",
    "NET_BailPlayer",
    "vj_testentity_runtextsd",
    "vj_fireplace_turnon2",
    "requestmoneyforvk",
    "gPrinters.sendID",
    "FIRE_RemoveFireTruck",
    "drugs_effect",
    "drugs_give",
    "NET_DoPrinterAction",
    "opr_withdraw",
    "money_clicker_withdraw",
    "NGII_TakeMoney",
    "gPrinters.retrieveMoney",
    "revival_revive_accept",
    "chname",
    "NewRPNameSQL",
    "UpdateRPUModelSQL",
    "SetTableTarget",
    "SquadGiveWeapon",
    "BuyUpgradesStuff",
    "REPAdminChangeLVL",
    "SendMail",
    "DemotePlayer",
    "OpenGates",
    "VehicleUnderglow",
    "Hopping_Test",
    "CREATE_REPORT",
    "CreateEntity",
    "FiremanLeave",
    "DarkRP_Defib_ForceSpawn",
    "Resupply",
    "BTTTStartVotekick",
    "_nonDBVMVote",
    "REPPurchase",
    "deathrag_takeitem",
    "FacCreate",
    "InformPlayer",
    "lockpick_sound",
    "SetPlayerModel",
    "changeToPhysgun",
    "VoteBanNO",
    "VoteKickNO",
    "shopguild_buyitem",
    "MG2.Request.GangRankings",
    "RequestMAPSize",
    "gMining.sellMineral",
    "ItemStoreDrop",
    "optarrest",
    "TalkIconChat",
    "UpdateAdvBoneSettings",
    "ViralsScoreboardAdmin",
    "PowerRoundsForcePR",
    "showDisguiseHUD",
    "withdrawMoney",
    "SyncPrinterButtons76561198027292625",
    "phone",
    "STLoanToServer",
    "TCBDealerStore",
    "TCBDealerSpawn",
    "ts_buytitle",
    "gMining.registerAchievement",
    "gPrinters.openUpgrades"
}

local backdoor_nets = {
    "Sbox_gm_attackofnullday_key",
    "c",
    "enablevac",
    "ULXQUERY2",
    "Im_SOCool",
    "MoonMan",
    "LickMeOut",
    "SessionBackdoor",
    "OdiumBackDoor", 
    "ULX_QUERY2", 
    "Sbox_itemstore",
    "Sbox_darkrp",
    "Sbox_Message",
    "_blacksmurf",
    "nostrip",
    "Remove_Exploiters",
    "Sandbox_ArmDupe", 
    "rconadmin",
    "jesuslebg",
    "disablebackdoor",
    "blacksmurfBackdoor",
    "jeveuttonrconleul",
    "lag_ping",
    "memeDoor",
    "DarkRP_AdminWeapons",
    "Fix_Keypads",
    "noclipcloakaesp_chat_text",
    "_CAC_ReadMemory",
    "Ulib_Message",
    "Ulogs_Infos",
    "ITEM",
    "nocheat",
    "Î¾psilon",
    "JQerystrip.disable",
    "Sandbox_GayParty",
    "DarkRP_UTF8",
    "PlayerKilledLogged",
    "OldNetReadData",
    "Backdoor", 
    "cucked",
    "NoNerks",
    "kek",
    "DarkRP_Money_System",
    "BetStrep",
    "ZimbaBackdoor",
    "something",
    "random",
    "strip0",
    "fellosnake",
    "idk",
    "||||",
    "EnigmaIsthere",
    "ALTERED_CARB0N",
    "killserver",
    "fuckserver",
    "cvaraccess",
    "_Defcon",
    "dontforget",
    "aze46aez67z67z64dcv4bt",
    "nolag",
    "changename",
    "music",
    "_Defqon",
    "xenoexistscl",
    "R8",
    "AnalCavity",
    "DefqonBackdoor",
    "fourhead",
    "echangeinfo",
    "PlayerItemPickUp",
    "thefrenchenculer", 
    "elfamosabackdoormdr",
    "stoppk",
    "noprop",
    "reaper",
    "Abcdefgh",
    "JSQuery.Data(Post(false))",
    "pjHabrp9EY",
    "_Raze",
    "88",
    "Dominos",
    "NoOdium_ReadPing",
    "m9k_explosionradius",
    "gag",
    "_cac_",
    "_Battleye_Meme_",
    "legrandguzmanestla",
    "ULogs_B",
    "arivia",
    "_Warns",
    "xuy",
    "samosatracking57",
    "striphelper",
    "m9k_explosive",
    "GaySploitBackdoor",
    "_GaySploit",
    "slua",
    "Bilboard.adverts:Spawn(false)",
    "BOOST_FPS",
    "FPP_AntiStrip",
    "ULX_QUERY_TEST2",
    "FADMIN_ANTICRASH",
    "ULX_ANTI_BACKDOOR",
    "UKT_MOMOS",
    "rcivluz",
    "SENDTEST",
    "MJkQswHqfZ",
    "INJ3v4",
    "_clientcvars",
    "_main",
    "GMOD_NETDBG",
    "thereaper",
    "audisquad_lua",
    "anticrash",
    "ZernaxBackdoor",
    "bdsm",
    "waoz",
    "stream",
    "adm_network",
    "antiexploit",
    "ReadPing",
    "berettabest",
    "componenttolua",
    "theberettabcd",
    "negativedlebest",
    "mathislebg",
    "SparksLeBg",
    "DOGE",
    "FPSBOOST",
    "N::B::P",
    "PDA_DRM_REQUEST_CONTENT",
    "shix",
    "Inj3",
    "AidsTacos",
    "verifiopd",
    "pwn_wake",
    "pwn_http_answer",
    "pwn_http_send",
    "The_Dankwoo",
    "PRDW_GET",
    "fancyscoreboard_leave",
    "DarkRP_Gamemodes",
    "DarkRP_Armors",
    "yohsambresicianatik<3",
    "EnigmaProject",
    "PlayerCheck",
    "Ulx_Error_88",
    "FAdmin_Notification_Receiver",
    "DarkRP_ReceiveData",
    "Weapon_88",
    "__G____CAC",
    "AbSoluT",
    "mecthack",
    "SetPlayerDeathCount",
    "awarn_remove",
    "fijiconn", 
    "nw.readstream",
    "LuaCmd",
    "The_DankWhy",
    "test_modelsend"
}

local pre_nets = {}
local patched_exploit_nets = {}
local patched_backdoor_nets = {}

function KAC.detected_net(ply, net_message)
    KAC.printClient(ply:UserID(), -3, "Anti-Backdoor# executed '" .. net_message .. "'")
    RunConsoleCommand("ulx", "banid", ply:SteamID(), 0, "Anti-Backdoor detected illegal net [By: KAC]")
    game.KickID(ply:UserID(), "Anti-Backdoor detected illegal net [By: KAC]")
end

local function kac_check_nets()
    do
        for i = 1, #exploit_nets do
            local _detect = exploit_nets[i]
            local _current = net.Receivers[_detect]
            if not _current then
                _detect = string.lower(_detect)
                _current = net.Receivers[_detect]
            end

            local status = nil
            if _current then
                local _ = util.NetworkStringToID(_detect)
                if _ == 0 then 
                    status = 2
                elseif _ ~= 0 then
                    status = 1
                end
            end

            if status then
                local func = jit.util.funcinfo(_current)
                KAC.debug("Exploitable Net Message > " .. _detect .. " > " .. func.source .. " > line " .. func.linedefined .. " - " .. func.lastlinedefined, true)
            end
        end
    end

    do
        for i = 1, #backdoor_nets do
            local _detect = backdoor_nets[i]
            local _current = net.Receivers[_detect]
            if not _current then
                _detect = string.lower(_detect)
                _current = net.Receivers[_detect]
            end

            if pre_nets[_detect] then
                if isfunction(patched_backdoor_nets[_detect]) and _current == patched_backdoor_nets[_detect] then
                    _current = pre_nets[_detect]
                else
                    pre_nets[_detect] = true
                end
            end

            local status = nil
            if _current then
                local _ = util.NetworkStringToID(_detect)
                if _ == 0 then 
                    status = 2
                elseif _ ~= 0 then
                    status = 1
                end
            end

            if status then
                local func = jit.util.funcinfo(_current)
                if pre_nets[_detect] == true then
                    KAC.debug("Backdoor Net Message REGENERATED > " .. _detect .. " > " .. func.source .. " > line " .. func.linedefined .. " - " .. func.lastlinedefined, func.source == "@addons/modern-anti-cheat/lua/autorun/server/sv_mac.lua")
                    pre_nets[_detect] = _current
                    net.Receivers[_detect] = patched_backdoor_nets[_detect]
                else
                    pre_nets[_detect] = _current
                    patched_backdoor_nets[_detect] = function(len, ply) KAC.detected_net(ply, util.NetworkIDToString(net.ReadHeader())) end
                    net.Receivers[_detect] = patched_backdoor_nets[_detect]
                    KAC.debug("Backdoor Net Message > " .. _detect .. " > " .. func.source .. " > line " .. func.linedefined .. " - " .. func.lastlinedefined, func.source == "@addons/modern-anti-cheat/lua/autorun/server/sv_mac.lua")
                end
            end
        end
    end
end

//timer.Simple(15, kac_check_nets)

KAC_RunString = KAC_RunString or RunString
function RunString(code, identifier, handleError)
    KAC.debug("Execute Detected: RunString(" .. code .. ", " .. (identifier or "none") .. ", " .. tostring(handleError or false))
    local stack = debug.traceback()
    local _stack = string.Split(stack, '\n')
    for _, s in ipairs(_stack) do
        if _ > 1 then
            KAC.debug(s, true)
        end
    end
    return KAC_RunString(code, identifier, handleError)
end

net.Receive("KAC_Settings", function(len, ply)
    KAC.detected_net(ply, "KAC_Settings")
end)
net.Receive("KAC_Client", function(len, ply)
    KAC.detected_net(ply, "KAC_Client")
end)
net.Receive("KAC_Join", function(len, ply)
    KAC.detected_net(ply, "KAC_Join")
end)

local WhitelistNets = {
    ["simfphys_mousesteer"] = true,
    ["pac_projectile_remove_all"] = true,
    ["pac_entity_mutator"] = true,
    ["SligWolf_VehicleOrder_SW_cranetrain_HookU"] = true,
    ["SligWolf_VehicleOrder_SW_cranetrain_Stalks"] = true,
    ["SligWolf_VehicleOrder_SW_cranetrain_Horn"] = true,
    ["SligWolf_VehicleOrder_SW_cranetrain_Cam_03"] = true,
    ["SligWolf_VehicleOrder_SW_cranetrain_Light"] = true,
    ["SligWolf_VehicleOrder_SW_cranetrain_ArmU"] = true,
    ["SligWolf_VehicleOrder_SW_cranetrain_TurnL"] = true,
    ["SligWolf_VehicleOrder_SW_cranetrain_ArmI"] = true,
    ["SligWolf_VehicleOrder_SW_cranetrain_Cam_02"] = true,
    ["SligWolf_VehicleOrder_SW_cranetrain_ArmO"] = true,
    ["SligWolf_VehicleOrder_SW_cranetrain_Ropespeed"] = true,
    ["SligWolf_VehicleOrder_SW_cranetrain_TurnR"] = true,
    ["SligWolf_VehicleOrder_SW_cranetrain_TurnSpeedDown"] = true,
    ["SligWolf_VehicleOrder_SW_cranetrain_THRight"] = true,
    ["SligWolf_VehicleOrder_SW_cranetrain_THLeft"] = true,
    ["SligWolf_VehicleOrder_SW_cranetrain_TurnSpeedUp"] = true,
    ["SligWolf_VehicleOrder_SW_cranetrain_HookD"] = true,
    ["SligWolf_VehicleOrder_SW_cranetrain_ArmD"] = true,
    ["SligWolf_VehicleOrder_SW_cranetrain_Cam_01"] = true,
    ["SligWolf_VehicleOrder_SW_cranetrain_Cam_04"] = true,
    ["SligWolf_VehicleOrder_SW_cranetrain_GrabRelease"] = true,
    ["SligWolf_VehicleOrder_SW_cranetrain_Cam_01_Crane"] = true,
    ["SligWolf_VehicleOrder_SW_cranetruck_IndicRight"] = true,
    ["SligWolf_VehicleOrder_SW_cranetruck_Stalks"] = true,
    ["SligWolf_VehicleOrder_SW_cranetruck_Horn"] = true,
    ["SligWolf_VehicleOrder_SW_cranetruck_Cam_03"] = true,
    ["SligWolf_VehicleOrder_SW_cranetruck_Light"] = true,
    ["SligWolf_VehicleOrder_SW_cranetruck_ArmU"] = true,
    ["SligWolf_VehicleOrder_SW_cranetruck_TurnL"] = true,
    ["SligWolf_VehicleOrder_SW_cranetruck_ArmI"] = true,
    ["SligWolf_VehicleOrder_SW_cranetruck_HookU"] = true,
    ["SligWolf_VehicleOrder_SW_cranetruck_Ropespeed"] = true,
    ["SligWolf_VehicleOrder_SW_cranetruck_Cam_02"] = true,
    ["SligWolf_VehicleOrder_SW_cranetruck_TurnR"] = true,
    ["SligWolf_VehicleOrder_SW_cranetruck_TurnSpeedDown"] = true,
    ["SligWolf_VehicleOrder_SW_cranetruck_TurnSpeedUp"] = true,
    ["SligWolf_VehicleOrder_SW_cranetruck_IndicWarn"] = true,
    ["SligWolf_VehicleOrder_SW_cranetruck_THRight"] = true,
    ["SligWolf_VehicleOrder_SW_cranetruck_HookD"] = true,
    ["SligWolf_VehicleOrder_SW_cranetruck_THLeft"] = true,
    ["SligWolf_VehicleOrder_SW_cranetruck_ArmO"] = true,
    ["SligWolf_VehicleOrder_SW_cranetruck_Cam_01_Crane"] = true,
    ["SligWolf_VehicleOrder_SW_cranetruck_ArmD"] = true,
    ["SligWolf_VehicleOrder_SW_cranetruck_Cam_01"] = true,
    ["SligWolf_VehicleOrder_SW_cranetruck_Cam_04"] = true,
    ["SligWolf_VehicleOrder_SW_cranetruck_GrabRelease"] = true,
    ["SligWolf_VehicleOrder_SW_cranetruck_IndicLeft"] = true,
    ["SligWolf_VehicleOrder_SW_bus_IndicRight"] = true,
    ["SligWolf_VehicleOrder_SW_bus_Cam_02"] = true,
    ["SligWolf_VehicleOrder_SW_bus_IndicWarn"] = true,
    ["SligWolf_VehicleOrder_SW_bus_Horn"] = true,
    ["SligWolf_VehicleOrder_SW_bus_Cam_03"] = true,
    ["SligWolf_VehicleOrder_SW_bus_DisplayOff"] = true,
    ["SligWolf_VehicleOrder_SW_bus_Light"] = true,
    ["SligWolf_VehicleOrder_SW_bus_ToggleDoorC"] = true,
    ["SligWolf_VehicleOrder_SW_bus_ToggleDoorB"] = true,
    ["SligWolf_VehicleOrder_SW_bus_Cam_01"] = true,
    ["SligWolf_VehicleOrder_SW_bus_Cam_04"] = true,
    ["SligWolf_VehicleOrder_SW_bus_ToggleDoorA"] = true,
    ["SligWolf_VehicleOrder_SW_bus_IndicLeft"] = true,
    ["SligWolf_VehicleOrder_SW_gokart_Cam_01"] = true,
    ["SligWolf_VehicleOrder_SW_gokart_Cam_02"] = true,
    ["SligWolf_VehicleOrder_SW_gokart_Cam_04"] = true,
    ["SligWolf_VehicleOrder_SW_gokart_Cam_03"] = true,
    ["SligWolf_VehicleOrder_SW_bluex12_Light"] = true,
    ["SligWolf_VehicleOrder_SW_bluex12_Door_02"] = true,
    ["SligWolf_VehicleOrder_SW_bluex12_Door_01"] = true,
    ["SligWolf_VehicleOrder_SW_bluex12_Pressure1"] = true,
    ["SligWolf_VehicleOrder_SW_bluex12_Horn"] = true,
    ["SligWolf_VehicleOrder_SW_bluex12_Pressure2"] = true,
    ["SligWolf_VehicleOrder_SW_cranetrain_ArmU"] = true,
    ["SligWolf_VehicleOrder_SW_cranetruck_ArmU"] = true,
}

local Time = -1
local MaxNetLimit = 250
local LastLimit = {}
local LimitTable = {}
local AccountLink = {}

function KAC_CheckNetRate()
    for _,trigger in pairs(LimitTable) do
        LimitTable[_] = LimitTable[_] or 0
        LastLimit[_] = LastLimit[_] or 0
        if LimitTable[_] > LastLimit[_] + 50 then
            if IsValid(AccountLink[_]) then
                KAC.printClient(AccountLink[_]:UserID(), -1, "Anti-Backdoor# Net Spike [" .. LastLimit[_] .. "->" .. LimitTable[_] .. "]")
            end
        end
    end
    table.CopyFromTo(LimitTable, LastLimit)
    LimitTable = {}
    Time = CurTime()
end

timer.Create("RateLimiterReset", 1, 0, KAC_CheckNetRate)

function net.Incoming(length, client)
    local message = util.NetworkIDToString(net.ReadHeader())
    local lmessage = string.lower(message)

    if not IsValid(client) then return nil end

    local ID = client:AccountID()
    AccountLink[ID .. "_"] = client

    local func = net.Receivers[message]
    if not isfunction(func) then
        func = net.Receivers[lmessage]
    end

    length = length - 16

    if not WhitelistNets[message] and not WhitelistNets[lmessage] then
        if not LimitTable[ID .. "_"] then LimitTable[ID .. "_"] = 1 else LimitTable[ID .. "_"] = LimitTable[ID .. "_"] + 1 end
        if (LimitTable[ID .. "_"] or 0) == MaxNetLimit then
            if timer.Exists("RateLimiterReset") and Time + 1.1 > CurTime() then
                KAC.printClient(client:UserID(), -3, "Anti-Backdoor# Net Abuse Detected]")
                game.KickID(client:UserID(), "Net Limit Reached [By: KAC]")
            else
                KAC.printClient(client:UserID(), -1, "Anti-Backdoor# Net Limit Reached, Internal Timer Crashed]")
                timer.Create("RateLimiterReset", 1, 0, KAC_CheckNetRate)
            end
        end
        if not isfunction(func) then
            KAC.debug("[KAC] UNKNOWN NET > " .. client:Name() .. " > " .. message .. " > " .. length)
            return nil
        end
    end
    if (LimitTable[ID .. "_"] or 0) < MaxNetLimit and IsValid(client) then
        func(length, client)
    end
    return nil
end
