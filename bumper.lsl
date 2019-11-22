/* Bumper.lsl
 *
 * Author  : Mu (tsumukuu Resident)
 *           https://bit.ly/2XFK5du
 *           secondlife:///app/agent/1c3643ed-7278-4e06-92b3-79aaa84102fc/about
 *
 * Summery : Bumper base script for SecondLife
 *
 * Intent  : When a agent bumps into this object while it is attached to an
 *           Agent, then play an animation and a sound. This type of item
 *           is freqently called a "Bumper" in SecondLife
 *
 * Requires: LSL Preprocessor. Please look at compiled version if you do not
 *           wish to use the LSL Preprocessor. At this time it appears that
 *           Preprocessor is only available on Firestorm
 *           More Info: https://wiki.firestormviewer.org/fs_preprocessor
 */

#define MAX_FORCE 2147483647.0  // Highest value of a 32bit float
#define RATE_LIMITED 3.0        // Undef RATE_LIMITED to disable
#define ANIMATION_PLAY_TIME 2.0 // How long should the animation play

//Strings used within the script. Should be descriptive enough.
#define _strAnimationNotFound "Animation was not found"
#define _strSoundNotFound "Sound was not found"
#define _strNotAttachedError "For this product to function, it must be attached"

//Set the vairables that are used within the script
string Animation = "crab"; //item name
string Sound     = "ce24d4e3-3394-8712-8dc7-69c812b734c7"; //UUID or item name
float  Volume    = 1.0; // Volume of sound 0.0 - 1.0

integer InventoryExists(integer type, string name){
    integer inventoryItem = llGetInventoryNumber(type);
    //if the string is a key, we don't need to worry
    if (type == INVENTORY_SOUND){
        if ((key)name){
            return TRUE;
        }
    }
    while (inventoryItem >= 0){
        if (llGetInventoryName(type, inventoryItem) == name){
            return TRUE;
        }
        inventoryItem --;
    }
    return FALSE;
}

integer ItemsExist(){
    if (!InventoryExists(INVENTORY_SOUND, Sound)){
        llOwnerSay(_strSoundNotFound);
        return FALSE;
    }
    if (!InventoryExists(INVENTORY_ANIMATION, Animation)){
        llOwnerSay(_strAnimationNotFound);
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
            llOwnerSay(_strNotAttachedError);
            state error;
        }
        if ((perm & PERMISSION_TRIGGER_ANIMATION) == 0) state permissions;
    }

    on_rez(integer start_param)
    {
        //Re-enter the state so we don't have to duplicate state_entry
        state default;
    }

    collision(integer index)
    {
        while(index > 0){
            //Go through all detected collisions looking for an Agent
            if (llDetectedType(--index) & AGENT) jump break;
        }
        //No agent was found, so leave script
        return;
        @break;
        llStartAnimation(Animation);  // Play the animation
        llPlaySound(Sound, Volume);   // Then play the sound
        llSleep(ANIMATION_PLAY_TIME); // Wait for a couple moments
        llStopAnimation(Animation);   // Stop the Animation
        #ifdef RATE_LIMITED
        llSleep(RATE_LIMITED);        // Rate limit the bumper
        #endif
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
        //If we are here we know we're waiting on permissions
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
