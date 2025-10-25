# 🏀 Basketball Demo - Player vs AI

## Overview
This is an interactive basketball game demo featuring:
- **YOU (Green Player)** - Controlled by keyboard
- **AI Opponent (Red Player)** - Automated AI player
- **Real Player Stats** - Your player uses the actual player data system
- **Live Scoring** - Track points as you play

## How to Run

### Option 1: Godot Editor (Recommended)
```bash
godot --editor
```
Then press **F5** or click **Play**

### Option 2: Direct Run
```bash
godot
```

## What You'll See

### Visual Elements:
1. **🏀 Basketball Court** - Brown wooden court with white center line
2. **🟢 Green Player (YOU)** - Your controllable character on the left
3. **🔴 Red Player (AI)** - AI opponent on the right
4. **🟠 Orange Ball** - Basketball that both players can grab
5. **Red & Blue Hoops** - Goals on each side of the court

### UI Display:
- **Title**: "🏀 Basketball Demo - Player vs AI"
- **Score**: Live score tracking (You - AI)
- **Controls**: Keyboard controls guide
- **Your Stats**: Real-time display of your player's stats (Speed, Accuracy, Level)

## Controls

### Movement:
- **W** - Move Up
- **A** - Move Left  
- **S** - Move Down
- **D** - Move Right

### Actions:
- **SPACE** - Shoot the ball (when you have possession)

## Gameplay

### How to Play:
1. **Move** to the ball using WASD keys
2. **Grab** the ball by touching it (automatic)
3. **Shoot** by pressing SPACE when near the left hoop
4. **Score** by getting the ball into the red hoop on the left
5. **Defend** against the AI trying to score on the right

### AI Behavior:
- The AI automatically chases the ball
- When AI gets the ball, it moves toward the left hoop
- AI will shoot when close to its goal

### Scoring:
- **You score**: When ball enters the left (red) hoop
- **AI scores**: When ball enters the right (blue) hoop
- **Bonus**: You gain 50 XP for each basket you make!

## Player System Integration

### Your Player Stats Affect Gameplay:
- **Speed Stat**: Higher speed = faster movement
  - Formula: Base speed × (1 + speed_stat × 0.1)
  - Example: Speed 5 = 50% faster movement!

- **Accuracy Stat**: Affects shooting precision (visual indicator)

- **Level**: Displayed in real-time, increases with XP

### Progression:
- Score baskets to earn **50 XP** per goal
- Level up to unlock better stats
- Your stats persist between game sessions

## Features Demonstrated

### ✅ Player System Features:
1. **Player Data Loading** - Your saved player data is used
2. **Real-time Stats** - Speed affects actual gameplay
3. **Experience Gain** - Earn XP by scoring
4. **Level Progression** - Level up during gameplay
5. **AI Opponent** - Separate AI player with own stats

### ✅ Visual Features:
1. **2D Court Rendering** - Visible basketball court
2. **Player Characters** - Colored circles with labels
3. **Ball Physics** - Ball movement and possession
4. **Score Tracking** - Live score display
5. **Smooth Movement** - Physics-based character control

### ✅ Game Mechanics:
1. **Player Control** - WASD keyboard input
2. **Ball Possession** - Grab and hold mechanics
3. **Shooting System** - Aim and shoot at hoops
4. **Collision Detection** - Players interact with ball
5. **AI Behavior** - Simple chase and shoot AI

## Technical Details

### Player Stats Impact:
```gdscript
// Your movement speed calculation:
speed = BASE_SPEED * (1.0 + player_stats.speed * 0.1)

// Example with Speed stat of 5:
speed = 200 * (1.0 + 5 * 0.1) = 200 * 1.5 = 300 pixels/second
```

### Court Dimensions:
- Width: 800 pixels
- Height: 600 pixels
- Player size: 40x40 pixels
- Ball size: 20x20 pixels

## Tips for Playing

1. **Stay Mobile**: Keep moving to intercept the ball
2. **Quick Shots**: Shoot as soon as you're near the hoop
3. **Block AI**: Position yourself between AI and the ball
4. **Level Up**: Score multiple baskets to gain XP and level up
5. **Watch Stats**: Your speed increases as you level up!

## What This Demonstrates

This demo proves that **Task 4 (Player System)** is fully integrated with actual gameplay:

✅ **Player data loads and works in real game**
✅ **Stats affect actual gameplay mechanics**  
✅ **Experience and leveling work during play**
✅ **Multiple players can exist simultaneously**
✅ **Visual representation of players and game**
✅ **Interactive controls and real-time updates**

## Next Steps

This basketball demo shows the foundation for:
- Full sports game implementation
- Multiplayer networking (replace AI with real player)
- More complex AI behaviors
- Advanced shooting mechanics
- Tournament modes
- Character customization visuals

---

**🎮 Ready to Play!**

Run the game and use WASD + SPACE to play basketball against the AI!
Your player stats from the player system directly affect your performance!