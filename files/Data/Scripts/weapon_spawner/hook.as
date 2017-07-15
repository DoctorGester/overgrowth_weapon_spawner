// Multiple players case
array<int> spawnedWeapons;

void Init(string levelName) {
    string weapon = GetConfigValueString("weapon_select_mod.selected_weapon");

    if (weapon.length() == 0) {
        return;
    }

    for (uint i = 0; i < spawnedWeapons.length(); i++) {
        if (ObjectExists(spawnedWeapons[i])) {
            Log(info, "Deleting a spawned weapon " + spawnedWeapons[i]);
            QueueDeleteObjectID(spawnedWeapons[i]);
        }
    }

    spawnedWeapons.resize(0);

    int items = GetNumItems();

    for (int i = 0; i < items; i++) {
        auto item = ReadItem(i);

        if (item.IsHeld()) {
            auto holder = item.HeldByWhom();
            auto object = ReadObjectFromID(holder);

            if (object.GetPlayer()) {
                QueueDeleteObjectID(item.GetID());
            }
        }
    }

    int numChars = GetNumCharacters();
    for(int i = 0; i < numChars; i++){
        auto char = ReadCharacter(i);
        auto object = ReadObjectFromID(char.GetID());

        if (object.GetPlayer()) {
            auto id = CreateObject(weapon, true);
            char.Execute("AttachWeapon(" + id + ")");
            spawnedWeapons.insertLast(id);
        }
    }
}

void ReceiveMessage(string msg) {
    if (msg == "post_reset") {
        Init("");
    }
}

void DrawGUI() {}
void Update(int paused) {  }
void SetWindowDimensions(int w, int h){}