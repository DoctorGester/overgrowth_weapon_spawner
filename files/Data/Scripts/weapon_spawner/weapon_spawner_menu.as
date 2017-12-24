#include "menu_common.as"
#include "music_load.as"

MusicLoad ml("Data/Music/menu.xml");

IMGUI@ imGUI;
int selectedWeapon = 0;
array<string> weaponLabels = { "knife", "spear", "staff", "rapier", "sword", "big_sword", "bow" };
array<string> weaponPaths = {
    ""
};

array<string> weaponNames = {
    "None"
};

bool HasFocus() {
    return false;
}

void LoadSpawnerItems() {
    auto active_mods = GetActiveModSids();

    weaponPaths.resize(1);
    weaponNames.resize(1);

    string savedWeaponPath = GetConfigValueString("weapon_select_mod.selected_weapon");

    int itemIndex = 0;

    for(uint i = 0; i < active_mods.length(); ++i) {
        auto items = ModGetSpawnerItems(active_mods[i]);
        auto modName = ModGetName(active_mods[i]);

        for(uint u = 0; u < items.length(); ++u) {
            auto path = items[u].GetPath();

            if (FileExists(path)) {
                if (LoadFile(path)) {
                    while (true) {
                        auto line = GetFileLine();

                        // I want to kill myself
                        if (line == "end") {
                            break;
                        }

                        auto tagOpen = "<label>";
                        auto tagClose = "</label>";
                        auto labelStart = line.findFirst(tagOpen);
                        auto labelEnd = line.findFirst(tagClose);

                        if (labelStart != -1 && labelEnd != -1) {
                            auto label = line.substr(
                                labelStart + tagOpen.length(),
                                labelEnd - labelStart - tagOpen.length()
                            );

                            if (weaponLabels.find(label) != -1) {
                                weaponNames.insertLast(modName + " - " + items[u].GetTitle());
                                weaponPaths.insertLast(path);

                                if (path == savedWeaponPath) {
                                    selectedWeapon = itemIndex + 1;
                                }

                                itemIndex++;
                            }
                        }
                    }
                }
            }
        }
    }
}

void Initialize() {
    @imGUI = CreateIMGUI();

    // We're going to want a 100 'gui space' pixel header/footer
    imGUI.setHeaderHeight(200);
    imGUI.setFooterHeight(200);

    // Actually setup the GUI -- must do this before we do anything
    imGUI.setup();
    BuildUI();
    setBackGround();

    LoadSpawnerItems();
}

void BuildUI(){
    int initial_offset = 0;
    IMDivider mainDiv( "mainDiv", DOHorizontal );
    mainDiv.setAlignment(CACenter, CACenter);
    //CreateMenu(mainDiv, my_campaign_levels, "my_campaign", initial_offset);
    // Add it to the main panel of the GUI
    imGUI.getMain().setElement( @mainDiv );
	IMDivider header_divider( "header_div", DOHorizontal );
	AddTitleHeader("Weapon Spawner", header_divider);
	imGUI.getHeader().setElement(header_divider);
    AddBackButton();
}

void Dispose() {
	imGUI.clear();
}

bool CanGoBack() {
    return true;
}

void Update() {
    imGUI.update();
	UpdateController();
	UpdateKeyboardMouse();

    while(imGUI.getMessageQueueSize() > 0) {
        IMMessage@ message = imGUI.getNextMessage();
        if(message.name == "Back") {
            this_ui.SendCallback("back");
        }
    }
}

void Resize() {
    imGUI.doScreenResize(); // This must be called first
    setBackGround();
}

void ScriptReloaded() {
    imGUI.clear();
    Initialize();
}

void DrawGUI() {
    imGUI.render();

    ImGui_Begin(
        "weapon_select",
        ImGuiWindowFlags_NoTitleBar |
        ImGuiWindowFlags_NoResize |
        ImGuiWindowFlags_NoMove |
        ImGuiWindowFlags_NoCollapse |
        ImGuiWindowFlags_NoSavedSettings
    );

    vec2 size = vec2(750, 50);

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
