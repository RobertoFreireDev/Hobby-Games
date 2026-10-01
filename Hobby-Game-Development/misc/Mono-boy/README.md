# Mono-boy

Games:
- Transform the racing game in a delivery boy game

Game Manager:
- To create objects with x,y animation, play animations, etc, create function in c# to return this reusable object
- Add drawrect with transparency with optional boolean value default false. With true, it will draw static position. It doesn't change if player moves on map

SpriteEditor:
 - Copy in SpriteEditor is not okay. Fix that to work more like in paint
 - Change how it draws the rectangle for selection in sprite editor

SAVE new data:
- Song, song page and time (SongEditorManager.SongMinLength. Load in the LoadContent for PlayGameManager)
- Map position
Note: Update these variables in Games.GetCurrentGame().VARIABLE to fix issue losing property when resizing screen