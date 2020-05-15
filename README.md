# Boss Randomizer
![visitors](https://visitor-badge.glitch.me/badge?page_id=talesrune.bossrand)\
Anyone can become a random boss after typing a command called **!bossrand** or **/bossrand** and everyone is able to use the command. There is a cooldown though.
 
Every boss has a PDA which blocks a backstab before a spy can insta-kill the boss. This is to ensure that the bosses will not die so easily by a single stab. The number of PDAs varies from different bosses. PDA is replaced with SDK Hooks as of May 2020.

# Commands
- **sm_bossrand** - Give that person a Random Boss.


# Admin commands
- **sm_bossrand_reload** - Reload config for BossRand.
- **sm_br** - Give that person a Random Boss. (E.g. No 1)  **sm_br hd @blue** ~ Transforms blue team to be Heavy Deflectors. (E.g. No 2)  **sm_br hd jack** ~ Transforms jack to be a Heavy Deflector.


# ConVars
- **bossrand_version** Shows Boss Randomizer version.
- **bossrand_enabled** *(1/0, def. 1)* Enables the plugin.
- **sm_bossrand_cooltime** *(def. 90.0)* Cooldown for Boss Randomizer. 0 to disable cooldown.


# Installation
**Your server needs both [TF2Items](https://builds.limetech.org/?p=tf2items) and [TF2 Give Weapon](https://forums.alliedmods.net/showthread.php?p=1337899) loaded!**
* Install bossrand.smx into your sourcemod/plugins/ directory.
* Install bossrand_boss.cfg into your sourcemod/configs/ directory.
* Install or edit (if you already have it) tf2items.givecustom.txt in your sourcemod/configs/ directory.
* To edit tf2items.givecustom.txt, copy and add the following weapons from **github's** tf2items.givecustom.txt: 7046,7047,7048,7040,7042,7045,7051,7052,7067,7068,7069,7034,7071,7057,7058,7061,7062,7063.
* Done!

# Directory
* configs folder - 1. bossrand_boss.cfg, 2. tf2items.givecustom.txt
* plugins folder - 1. bossrand.smx
* scripting folder - 1. bossrand.sp

# Credits
* FlaminSarge - Based from his plugin: Be the Horsemann
