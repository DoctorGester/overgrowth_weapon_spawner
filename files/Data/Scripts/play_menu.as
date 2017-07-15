#include "menu_common.as"
#include "music_load.as"

MusicLoad ml("Data/Music/menu.xml");

const int item_per_screen = 4;
const int rows_per_screen = 3;

IMGUI imGUI;
array<LevelInfo@> play_menu = {	LevelInfo("tutorial.xml",		"Tutorial",			"Textures/ui/menus/main/tutorial.jpg"),
								LevelInfo("campaign_menu.as",	"Main Campaign",	"Textures/ui/menus/main/main_campaign.jpg", true),
								LevelInfo("lugaru_menu.as",		"Lugaru Campaign",	"Textures/lugarumenu/smallest_Village_2.jpg")};

bool HasFocus() {
    return false;
}

void Initialize() {

    // Start playing some music
    PlaySong("overgrowth_main");

    // We're going to want a 100 'gui space' pixel header/footer
	imGUI.setHeaderHeight(200);
    imGUI.setFooterHeight(200);

	imGUI.setFooterPanels(200.0f, 1400.0f);
    // Actually setup the GUI -- must do this before we do anything
    imGUI.setup();
    SetPlayMenuList();
    BuildUI();
	setBackGround();
	AddVerticalBar();
}

void SetPlayMenuList(){
    array<ModID>@ active_sids = GetActiveModSids();
    for( uint i = 0; i < active_sids.length(); i++ ) {
        array<MenuItem>@ menu_items = ModGetMenuItems(active_sids[i]); 
        for( uint k = 0; k < menu_items.length(); k++ ) {
            if( menu_items[k].GetCategory() == "play" ) {
                string thumbnail_path = menu_items[k].GetThumbnail();
                if( thumbnail_path == "" ) {
                    thumbnail_path = "../" + ModGetThumbnail(active_sids[i]);
                }
				play_menu.insertLast(LevelInfo(menu_items[k].GetPath(), menu_items[k].GetTitle(), thumbnail_path));
            }
        }
        Campaign camp = ModGetCampaign(active_sids[i]);
        if( camp.GetType() == "general" ) {
            string camp_thumbnail_path = camp.GetThumbnail();
            if( camp_thumbnail_path == "" ) {
                camp_thumbnail_path = "../" + ModGetThumbnail(active_sids[i]);
            }
			play_menu.insertLast(LevelInfo("general_campaign_menu.as", camp.GetTitle(), camp_thumbnail_path, ModGetID(active_sids[i])));
        }
    }
    AddCustomLevelsMenuItem();
}

void BuildUI(){
    IMDivider mainDiv( "mainDiv", DOHorizontal );
	IMDivider header_divider( "header_div", DOHorizontal );
	header_divider.setAlignment(CACenter, CACenter);
	AddTitleHeader("Select Campaign", header_divider);
	imGUI.getHeader().setElement(header_divider);

    int initial_offset = 0;
    if( StorageHasInt32("play_menu-shift_offset") ) {
        initial_offset = StorageGetInt32("play_menu-shift_offset");
    }
    while( initial_offset >= int(play_menu.length()) ) {
        initial_offset -= item_per_screen;
        if( initial_offset < 0 ) {
            initial_offset = 0;
            break;
        }
    }
	CreateMenu(mainDiv, play_menu, "play_menu", initial_offset, item_per_screen, rows_per_screen, false, false);
    // Add it to the main panel of the GUI
    imGUI.getMain().setElement( @mainDiv );
	AddBackButton();
}

void AddCustomLevelsButton(){
	if(NrCustomLevels() != 0){
		IMDivider custom_levels_divider("custom_levels_divider", DOHorizontal);
		float text_trailing_space = 75.0f;
		float button_width = 500.0f;
		AddButton("Custom Levels", custom_levels_divider, "null", button_background_diamond, true, button_width, text_trailing_space, mouseover_scale_button);
		imGUI.getFooter(1).setElement(custom_levels_divider);
	}
}

void AddCustomLevelsMenuItem(){
	if(NrCustomLevels() != 0){
		play_menu.insertLast(LevelInfo("custom_levels.as", "Custom Levels", "Textures/ui/menus/main/custom_level_thumbnail.jpg"));
	}
}

void Dispose() {
    imGUI.clear();
}

bool CanGoBack() {
    return true;
}

void Update() {
	UpdateKeyboardMouse();
    // process any messages produced from the update
    while( imGUI.getMessageQueueSize() > 0 ) {
        IMMessage@ message = imGUI.getNextMessage();

        if( message.name == "run_file" ) 
        {
			string inter_level_data = play_menu[message.getInt(0)].inter_level_data;
			if(inter_level_data != ""){
				SetInterlevelData("current_mod_campaign", inter_level_data);
			}
            this_ui.SendCallback(message.getString(0));
        }
        else if( message.name == "Tutorial" ) 
        { 
            this_ui.SendCallback("tutorial.xml");
        } 
        else if( message.name == "Main Campaign" ) 
        {
            this_ui.SendCallback("campaign_menu.as");
        } 
        else if( message.name == "Lugaru" ) 
        {
            this_ui.SendCallback("lugaru_menu.as");
        }
        else if( message.name == "Arena" )
        {
            this_ui.SendCallback( "arena_menu.as" );
        }
        else if( message.name == "mod_campaign" ) 
        {
            SetInterlevelData("current_mod_campaign",message.getString(0));
            this_ui.SendCallback("general_campaign_menu.as");
        }
        else if( message.name == "Play" )
        {
            this_ui.SendCallback(message.getString(0));
        }
        else if( message.name == "Versus" )
        {
            this_ui.SendCallback("Project60/22_grass_beach.xml");
        }
		else if( message.name == "Custom Levels" )
        {
			this_ui.SendCallback( "custom_levels.as" );
        }
        else if( message.name == "Back" )
        {
            this_ui.SendCallback( "back" );
        }
		else if( message.name == "shift_menu" ){
            StorageSetInt32("play_menu-shift_offset", ShiftMenu(message.getInt(0)));
            SetControllerItemBeforeShift();
            BuildUI();
            SetControllerItemAfterShift(message.getInt(0));
		}
        else if( message.name == "refresh_menu_by_name" ){
			string current_controller_item_name = GetCurrentControllerItemName();
			BuildUI();
			SetCurrentControllerItem(current_controller_item_name);
		}
		else if( message.name == "refresh_menu_by_id" ){
			int index = GetCurrentControllerItemIndex();
			BuildUI();
			SetCurrentControllerItem(index);
		}
    }
	// Do the general GUI updating
    imGUI.update();
	UpdateController();
}

void Resize() {
    imGUI.doScreenResize(); // This must be called first
	setBackGround();
	AddVerticalBar();
}

void ScriptReloaded() {
    // Clear the old GUI
    imGUI.clear();
    // Rebuild it
    Initialize();
}

int selectedWeapon = 0;

void DrawGUI() {
    imGUI.render();

    array<string> weaponPaths = {
        ""
    };

    array<string> weaponNames = {
        "None"
    };

    JSON json;
    json.parseFile("Data/SpawnerObjects/interactiveobjects.json");

    auto objects = json.getRoot()["objects"];

    for (uint i = 0; i < objects.size(); i++) {
        auto path = objects[i][1].asString();

        if (path.findFirst("/gear/") != -1 || path.findFirst("/collectable/") != -1) {
            continue;
        }

        weaponNames.insertLast(objects[i][0].asString());
        weaponPaths.insertLast(path);
    }

    auto mods = GetActiveModSids();

    for (uint i = 0; i < mods.length(); i++) {
        auto mod = mods[i];
        auto items = ModGetMenuItems(mod);

        //Log(info, ModGetName(mod) + " " + items.size() + "");
        for (uint j = 0; j < items.length(); j++) {
            Log(info, items[j].GetPath());
        }
    }

    string weapon = GetConfigValueString("weapon_select_mod.selected_weapon");

    for (uint i = 0; i < weaponPaths.length(); i++) {
        if (weaponPaths[i] == weapon) {
            selectedWeapon = i;
            break;
        }
    }

    ImGui_Begin(
        "weapon_select",
        ImGuiWindowFlags_NoTitleBar |
        ImGuiWindowFlags_NoResize |
        ImGuiWindowFlags_NoMove |
        ImGuiWindowFlags_NoCollapse |
        ImGuiWindowFlags_NoSavedSettings
    );

    vec2 size = vec2(250, 50);

    ImGui_SetWindowPos(vec2(GetScreenWidth() / 2 - size.x / 2, 150 - size.y / 2));
    ImGui_SetWindowSize(size);

    ImGui_Text("Select a weapon to spawn with");
    if (ImGui_Combo("###WeaponSelectCombo", selectedWeapon, weaponNames)) {
        SetConfigValueString("weapon_select_mod.selected_weapon", weaponPaths[selectedWeapon]);
    }
    ImGui_End();
}

void Draw() {

}

void Init(string str) {

}