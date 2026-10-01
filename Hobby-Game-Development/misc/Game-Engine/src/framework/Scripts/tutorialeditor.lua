local tutorialeditor={
    firsttime = true,
    tutorialpages = {},
    currenttutorialpage = 1,
}

function drawtutorialtext(text,x,y)
    _print(text,20 + x,20 + y,_colors.primary,true)
end

function tutorialeditor:create()
    local firstpage = { category = "BlackBox" }
    function firstpage:draw()
        drawtutorialtext("[c10]Use 'Q' and 'E' to navigate pages[c10]",0,0)
        drawtutorialtext("[c09]BlackBox[c10] starts as a blank canvas\nUse Lua scripts to build custom tools, editors and games",0,20)
        drawtutorialtext("- [c09]NLua[c10] --version 1.7.5\n- [c09]MonoGame.Framework.DesktopGL[c10] --version 3.8.4\n- Mix of [c09]ANB16[c10] and [c09]Sweetie 16[c10] palettes. Ref: lospec.com",0,50)
    end

    local hotkeystutorial = { category = "Global hotkeys" }
    function hotkeystutorial:draw()
        drawtutorialtext("BlackBox:\n- [c09]main.lua[c10] file: Entry point\n- Exit: [c10]Alt + F4[c10]\n- Toggle Fullscreen: [c10]F2[c10]\nmain.lua:\n- Toggle Menu: [c10]F3[c10]\n- Restart: [c10]Esc[c10]\n- Save: [c10]Ctrl + R[c10]",0,0)
    end

    local spriteeditor = { category = "Sprite Editor" }
    function spriteeditor:draw()
        drawtutorialtext("Sprite Editor Controls:",0,0)
        drawtutorialtext("- [c10]A,W,S,D[c10] -> translate sprite",0,10)
        drawtutorialtext("- [c10]Ctrl + Z[c10] -> undo",0,20)
        drawtutorialtext("- [c10]Ctrl + Y[c10] -> redo",0,30)
        drawtutorialtext("- [c10]Ctrl + C[c10] -> copy",0,40)
        drawtutorialtext("- [c10]Ctrl + V[c10] -> paste",0,50)
        drawtutorialtext("- [c10]Hold Ctrl + click[c10] -> draw full circle/rect",0,60)
        drawtutorialtext("- [c10]Mouse scroll[c10] -> zoom in sprite editor",0,70)
    end

    local mapeditor = { category = "Map Editor" }
    function mapeditor:draw()
        drawtutorialtext("Map Editor Controls:",0,0)
        drawtutorialtext("- [c10]A,W,S,D[c10] -> move view on map",0,10)
        drawtutorialtext("- [c10]Hold Ctrl + click[c10] -> draw block of sprites",0,20)
    end

    local sfxeditor = { category = "Sfx Editor" }
    function sfxeditor:draw()
        drawtutorialtext("Sfx Editor Controls:",0,0)
        drawtutorialtext("- [c10]Q,E[c10] -> navigate sfx",0,10)
        drawtutorialtext("- [c10]A,D[c10] -> change sfx speed",0,20)
        drawtutorialtext("- [c10]Space[c10] -> play sfx",0,30)        
    end

    -- Add all pages
    add(tutorialeditor.tutorialpages, firstpage)
    add(tutorialeditor.tutorialpages, hotkeystutorial)
    add(tutorialeditor.tutorialpages, spriteeditor)
    add(tutorialeditor.tutorialpages, mapeditor)
    add(tutorialeditor.tutorialpages, sfxeditor)
end

function tutorialeditor:init()
    if self.firsttime then
        self:create()
        self.firsttime = false
    end
end

function tutorialeditor:update()
    self.currenttutorialpage = movepage(1,self.currenttutorialpage,#self.tutorialpages)
    local page=self.tutorialpages[self.currenttutorialpage]
    if page.update then
        page:update()
    end
end

function tutorialeditor:draw()
   local page=self.tutorialpages[self.currenttutorialpage]
   if page.draw then
        _print("PAG#: "..self.currenttutorialpage.." ".."("..page.category..")",12,2, _colors.tertiary)
        page:draw()
    end
end

return tutorialeditor