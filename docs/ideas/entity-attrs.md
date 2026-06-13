
## Current

character: name, status, controlling user, image placeholder field
NPC: name, apparent/real status, faction ref, image placeholder, stat block JSON placeholder
party: name
faction: name, status, parent faction
location: name, location type, status, parent location, image placeholder
quest: title, status, priority, major/minor, parent quest
session: title, session date, status
plot arc: title, status
encounter: title, encounter type, status, related session/plot arc
timeline event: title, date expression, sort key, event type, related session

### Character
- StatsSummary
  - configurable set of useful info for GM (and potentially players)
  {
    "name" : "name of the stat - used for tooltops",
    "display" : "short version of stat used in display",
    "type:" : "numeric or text",
    "minValue" : "optional, only applies if numeric",
    "maxValue" : "optional, only applies if numeric",
    "isStatic" : "if true, then use character editor to update, if false, allow inline editing.",
  }
  - have 'character stat sets', with sensible defaults. start with DnD
  - DnD default set = [Armour Class (AC), MaxHP, Passive Perception (PP), Passive Investigation (PInv), Passive Insight (PIns)]
  - DnD extended set = [DnD Default Set] + [Stat Bonuses + Saves + Skills + Vision]
- Species: free text for now
- Class : [
    {
    "class":"classname",
    "subclass": "subclass name", //optional
    "level" : 4
    },
    {
    "class":"classname2",
    "subclass": "subclass name 2", //optional
    "level" : 2
    }
    ]


### 