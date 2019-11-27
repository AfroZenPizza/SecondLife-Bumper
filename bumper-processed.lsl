/* Bumper.lsl
 *
 * Author  : Mu (tsumukuu Resident)
 *           https://bit.ly/2XFK5du
 *           secondlife:///app/agent/1c3643ed-7278-4e06-92b3-79aaa84102fc/about
 *
 * Summery : Bumper base script for SecondLife. This is the processed version.
 *           This means that this version does not require a Preprocessor. This
 *           script may be copyied and pasted into an empty script in SecondLife
 *
 * Intent  : When a agent bumps into this object while it is attached to an
 *           Agent, then play an animation and a sound. This type of item
 *           is freqently called a "Bumper" in SecondLife
 *
 * Note    : This version is not maintained with the Preprocessor version. It
 *           may have a few differences.
 *
 * Github  : https://github.com/AfroZenPizza/SecondLife-Bumper
 */

//Set the vairables that are used within the script
string Animation = "crab"; // Item name
string Sound     = "ce24d4e3-3394-8712-8dc7-69c812b734c7"; // UUID or item name
float  Volume    = 1.0;    // Volume of sound 0.0 - 1.0
float AnimTime   = 2.0;    // How long should the animation play
integer RateLimit  = 3;    // Set this to 0 to disable rate limiting

// Variables used internally. These should not be set during initialization
integer Checks;      //Contains bitwise constants for determining events
integer CooldownEnd; //When the cooldown should end. Set with llGetUnixTime()

/**
 * Check if item with a given name exists.
 *
 * Goes though the inventory of the item in which the script is operating
 * checking for an item of a given type and name exists. This is a nescessary
 * step in ensuring that errors are avoided due to attempts to use an inventory
 * item does not exist
 *
 * Args:
 *     type: SecondLife constant for inventory type. Expected values
 *             INVENTORY_ALL       INVENTORY_OBJECT     INVENTORY_NONE
 *             INVENTORY_TEXTURE   INVENTORY_NOTECARD   INVENTORY_GESTURE
 *             INVENTORY_SOUND     INVENTORY_SCRIPT     INVENTORY_SETTING
 *             INVENTORY_LANDMARK  INVENTORY_BODYPART
 *             INVENTORY_CLOTHING  INVENTORY_ANIMATION
 *
 * Returns:
 *     TRUE (1) if given item was found.
 *     FALSE(0) if given item was not found.
 */

integer InventoryExists(integer type, string name){
    integer inventoryItem = llGetInventoryNumber(type);
    // If the string is a key, we don't need to worry
    if (type == INVENTORY_SOUND){
        if ((key)name){
            return TRUE;
        }
    }
    while (inventoryItem--){
        if (llGetInventoryName(type, inventoryItem) == name){
            return TRUE;
        }
    }
    return FALSE;
}

/**
 * Checks for files required by this script
 *
 * Checks if the items nescessary for this script exist in the inventory of the
 * item which the script resides in. This is a helper function as this code
 * needs gets used multiple spots in this script. If more items are needed by
 * the script, this is where the checks should be handled.
 *
 * Returns:
 *     TRUE (1) if all items required are found
 *     FALSE(0) if any items are missing.
 */

integer ItemsExist(){
    if (!InventoryExists(INVENTORY_SOUND, Sound)){
        llOwnerSay("Sound was not found");
        return FALSE;
    }
    if (!InventoryExists(INVENTORY_ANIMATION, Animation)){
        llOwnerSay("Animation was not found");
        return FALSE;
    }
    return TRUE;
}

default
{
    state_entry()
    {
        integer perm = llGetPermissions();
        if (!ItemsExist()) state error;
        if (llGetAttached() == FALSE){
            llOwnerSay("For this product to function, it must be attached");
            state error;
        }
        if ((perm & PERMISSION_TRIGGER_ANIMATION) == 0) state permissions;
    }

    on_rez(integer start_param)
    {
        // Re-enter the state so we don't have to duplicate state_entry
        state default;
    }

    collision_end(integer index)
    {
        if (0x1 & Checks) return; // We're in cooldown
        integer agentWasDetected;
        while(index--){
            // Go through all detected collisions looking for an Agent
            if (llDetectedType(index) & AGENT) agentWasDetected = TRUE;
            // This would be where modification would be needed to handle
            // More Agent impacts if they occur.
        }
        if (agentWasDetected){
            if (agentWasDetected){
                Checks = Checks | 0x1;
                llStartAnimation(Animation);           // Play the animation
                Checks = Checks | 0x2;                 // Set the animation bit
                llPlaySound(Sound, Volume);            // Then play the sound
                llSetTimerEvent(AnimTime);             // Wait for a moment
                CooldownEnd = llGetUnixTime() + RateLimit;
            }
        }
    }

    timer()
    {
        llSetTimerEvent(0.0);
        if (CooldownEnd < llGetUnixTime()){
            //End Collision Cooldown and allow Collisions to occur again
            Checks = Checks & ~0x1;
        }
        if (Checks & 0x2){
            llStopAnimation(Animation);
            Checks = Checks & ~0x2;
            if (CooldownEnd > llGetUnixTime()){
                llSetTimerEvent(CooldownEnd - llGetUnixTime());
            }
        }
    }

    changed(integer change)
    {
        if (change & CHANGED_INVENTORY){
            // If the items in the inventory changes, recheck the items
            if (!ItemsExist()) state error;
            state default;
        }
    }

}

state error{
    on_rez(integer start_param)
    {
        state default;
    }

    attach(key id)
    {
        state default;
    }

    changed(integer change)
    {
        if (change & CHANGED_INVENTORY){
            // If the items in the inventory changes, recheck the items
            if (!ItemsExist()) state error;
            state default;
        }
    }

}

state permissions{
    state_entry()
    {
        // If we are here we know we're waiting on permissions
        llRequestPermissions(llGetOwner(), PERMISSION_TRIGGER_ANIMATION);
    }

    on_rez(integer start_param)
    {
        state default;
    }

    attach(key id)
    {
        state default;
    }

    run_time_permissions(integer perm)
    {
        if (perm & PERMISSION_TRIGGER_ANIMATION){
            // If we have the permissions we need, go back to work
            state default;
        }
    }

}
