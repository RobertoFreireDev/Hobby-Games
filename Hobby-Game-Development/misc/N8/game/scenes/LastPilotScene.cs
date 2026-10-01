namespace game.scenes;

internal class LastPilotScene : SceneBase
{
    private static INPico8API A => NGame.API;

    protected override string DataFolder => "lastpilot";

    private const float DT = 0.5f;
    private const float FillSpeed = 1f;
    private const float DrainSpeed = 1f;

    // --- Types ---
    private record struct HB(float X, float Y, float W, float H);

    private class Ptcl { public float x, y, dx, dy, rad, act, clr; }

    private class CloseStar { public float x, y, dx; public int spt, size; }

    private class Bullet
    {
        public float x, y, a, c;
        public HB hb = new(0, 0, 4, 2);
    }

    private class EnBullet
    {
        public float x, y;
        public HB hb = new(0, 0, 2, 2);
    }

    private class Item
    {
        public int s;
        public float x, y;
        public HB hb = new(0, 0, 8, 8);
    }

    private class Enemy
    {
        public float x, y, dy = 1, dytmr = 2, bltmr, cbltmr, yMin, yMax, htmr;
        public int s, l;
        public HB hb;
    }

    private class Player
    {
        public float x = 56, y = 56, v = 0.5f, shda = 0;
        public int s = 1, l = 3, pwr = 0, bt = 0, shds = 32;
        public HB hb = new(1, 3, 12, 10);
        public List<Bullet> b = new();
    }

    // --- Static data ---
    private static readonly (int spr, HB hb, int l, int bltmrv, int dym)[] Enys =
    {
        (3,  new HB(5, 4,  7,  8), 1,  -1, 16),
        (9,  new HB(5, 4, 10,  8), 2, 120,  0),
        (11, new HB(2, 2, 12, 12), 5, 100,  8),
        (37, new HB(6, 0,  6, 16), 4, 100, 12),
        (39, new HB(3, 1,  8, 14), 3, 100, 16),
        (41, new HB(3, 1,  8, 14), 2,  60, 16),
    };

    private static readonly string[] NamesByLevel =
        { "recruit", "rookie", "pro", "veteran", "general", "master" };

    private static readonly (int spt, int size)[] StrSpts = { (68, 4), (72, 2), (74, 1) };

    // --- Game state ---
    private Player p = new();
    private List<Enemy> e = new();
    private List<EnBullet> enbl = new();
    private List<Ptcl> prt = new(), str = new(), rct = new(), vcm = new();
    private CloseStar? str2;
    private Item? it;

    private float barValue, shakeIntensity, shakeDuration;
    private float ltmr, restartimer, ittmr, entmr, enstpt;
    private float badgetmr, finishtmr;
    private int score, level, shields, gametmr, maxlevel;
    private bool youlose, finish;

    // --- Intro state ---
    private bool introoption, blink, done, info;
    private float inttmrs, countcoverart, blinkTimer;
    private const float BlinkDuration = 60f;

    protected override void OnEnter()
    {
        maxlevel = 1;
        IntRest();
        InitIntro();
    }

    protected override void OnExit() { }

    internal override void Update(float elapsedGameTime)
    {
        if (introoption) { UpdateIntro(); return; }
        if (youlose) { UpdateVcm(); UpdtRest(); return; }

        StrMake();
        UpdateStr();
        UpdatePrt();
        UpdateRct();

        if (gametmr > 0) { gametmr--; return; }

        UpdatePlayer();
        UpdateItem();
        UpdateScore();

        if (!finish) RndEnemy();

        foreach (var ei in e.ToList()) UpdateEnemy(ei);
        foreach (var b in enbl.ToList()) UpdateEnBullet(b);
    }

    internal override void Draw()
    {
        A.cls();

        if (introoption) { DrawIntro(); return; }
        if (youlose) { PrtDraw(vcm); return; }

        if (p.x < 1) A.rect(0, 0, 1, 128, 1);

        var (sx, sy) = GetShakeOffset();
        A.camera(sx, sy);

        PrtDraw(str);
        PrtDraw(rct);

        foreach (var ei in e) DrawEnemy(ei);
        foreach (var b in enbl) DrawEnBullet(b);

        PrtDraw(prt);
        DrawPlayer();
        DrawItem();
        DrawCloseStar();

        A.camera();
        DrawHud();
        DrawScore();
        DrawBar();

        if (finish)
        {
            if (finishtmr > 0 && e.Count == 0 && enbl.Count == 0) finishtmr--;
            if (finishtmr == 0)
                A.print("you saved the earth!", 30, 54, 10);
        }
    }

    // ===================== PLAYER =====================

    private void UpdatePlayer()
    {
        if (p.l == 0) { Restart(); return; }

        if (shields > 0 && p.shda == 0 && A.btn(5))
        {
            shields--;
            p.shda = 90;
        }

        if (p.shda > 0) p.shda--;

        p.s = 1;
        p.hb = new HB(1, 3, 12, 10);

        if (p.y > 8   && A.btn(2)) { p.y -= p.v; p.s = 7; }
        if (p.y < 112 && A.btn(3)) { p.y += p.v; p.s = 5; }
        if (p.x < 112 && A.btn(1)) { p.x += p.v; RctMake(p.x, p.y + 3); A.sfx(2); }
        if (p.x >= 0  && A.btn(0)) p.x -= p.v;

        if (A.btn(4) && p.bt == 0 && barValue <= 80)
        {
            p.b.Add(new Bullet { x = p.x + 16, y = p.y + 7, a = 15 + p.pwr, c = 8 });
            p.bt = 1;
            A.sfx(0);
        }

        barValue += A.btn(4) ? FillSpeed : -DrainSpeed;
        barValue = (float)A.mid(0, barValue, 100);

        if (p.s == 7)      p.hb = new HB(1, 5, 12, 8);
        else if (p.s == 5) p.hb = new HB(1, 3, 12, 8);

        if (p.bt > 0) p.bt++;
        if (p.bt > 10) p.bt = 0;

        foreach (var b in p.b.ToList())
        {
            b.a--;
            b.c = 10 - (float)A.flr(b.a / 5);
            if (b.a < 0 || b.x > 128) { p.b.Remove(b); continue; }
            b.x += 2 * DT;
        }

        if (it != null && RectOverlap(it.hb, it.x, it.y, p.hb, p.x, p.y))
        {
            if (it.s == 34) { if (p.l < 3) { p.l++; A.sfx(4); } }
            else if (it.s == 35) { p.pwr = 8; A.sfx(4); }
            it = null;
        }

        bool damage = false;

        foreach (var ei in e.ToList())
        {
            if (ei.x < -8)
            {
                damage = true;
                DamageEnemy(ei);
            }
            else if (RectOverlap(ei.hb, ei.x, ei.y, p.hb, p.x, p.y))
            {
                if (p.shda == 0) { damage = true; p.shda = 90; }
                DamageEnemy(ei);
            }
        }

        if (damage) { DamagePlayer(); return; }

        foreach (var enbli in enbl.ToList())
            foreach (var b in p.b.ToList())
                if (RectOverlap(enbli.hb, enbli.x, enbli.y, b.hb, b.x, b.y))
                    enbl.Remove(enbli);

        foreach (var enbli in enbl.ToList())
        {
            if (RectOverlap(enbli.hb, enbli.x, enbli.y, p.hb, p.x, p.y))
            {
                if (p.shda == 0) { damage = true; p.shda = 90; }
                enbl.Remove(enbli);
            }
        }

        if (damage) DamagePlayer();
    }

    private void DamagePlayer()
    {
        p.pwr = 0;
        p.v = DT;
        p.l--;
        ltmr = 5;
        ShakeScreen(4, 10);
        A.sfx(1);
    }

    private void DrawPlayer()
    {
        foreach (var b in p.b)
            A.rectfill((int)b.x, (int)b.y, (int)(b.x + 8 + 3 * A.flr(b.a / 5)), (int)(b.y + 1), (int)b.c);

        if (barValue > 80) A.pal(9, 8);
        A.spr(p.s, (int)p.x, (int)p.y, 2, 2);
        A.pal();

        int shda = (int)p.shda;
        if (shda > 50)
            A.spr(p.shds, (int)p.x, (int)p.y, 2, 2);
        else if (shda > 25 && shda % 10 < 5)
            A.spr(p.shds, (int)p.x, (int)p.y, 2, 2);
        else if (shda > 0 && shda % 6 < 3)
            A.spr(p.shds, (int)p.x, (int)p.y, 2, 2);
    }

    // ===================== ENEMY =====================

    private void RndEnemy()
    {
        entmr--;
        if (entmr > 0) return;

        entmr = badgetmr + 100 + A.rnd(32);

        var ypos = new List<float> { 3, 4, 5 };
        ypos.Remove(enstpt);
        enstpt = ypos[A.rnd(ypos.Count)];

        int idx = A.rnd((int)A.min(level + 1, Enys.Length));
        var (spr, hb, l, bltmrv, dym) = Enys[idx];

        e.Add(new Enemy
        {
            x = 130, y = enstpt * 16,
            s = spr, l = l, hb = hb,
            bltmr = bltmrv, cbltmr = bltmrv,
            yMin = enstpt * 16 - dym,
            yMax = enstpt * 16 + dym,
        });
    }

    private void UpdateEnemy(Enemy ei)
    {
        ei.x -= DT;
        ei.htmr--;

        if (ei.yMax > ei.yMin)
        {
            if (ei.dytmr > 0) ei.dytmr--;
            else
            {
                ei.dytmr = 2;
                ei.y += ei.dy;
                if (ei.y >= ei.yMax || ei.y <= ei.yMin) ei.dy = -ei.dy;
            }
        }

        if (ei.bltmr >= 0)
        {
            if (ei.bltmr > 0) ei.bltmr--;
            else
            {
                ei.bltmr = ei.cbltmr;
                enbl.Add(new EnBullet { x = ei.x - 2, y = ei.y + 7 });
            }
        }

        foreach (var b in p.b.ToList())
        {
            if (RectOverlap(b.hb, b.x, b.y, ei.hb, ei.x, ei.y))
            {
                p.b.Remove(b);
                ei.l--;
                ei.htmr = 5;
                if (ei.l == 0) DamageEnemy(ei);
            }
        }
    }

    private void DamageEnemy(Enemy ei)
    {
        e.Remove(ei);
        score++;
        PrtMake(ei.x + ei.hb.X + ei.hb.W / 2, ei.y + ei.hb.Y + ei.hb.H / 2);
        A.sfx(1);
    }

    private void DrawEnemy(Enemy ei)
    {
        if (ei.htmr > 0) A.pal(6, 10);
        A.spr(ei.s, (int)ei.x, (int)ei.y, 2, 2);
        A.pal();
    }

    // ===================== ENEMY BULLETS =====================

    private void UpdateEnBullet(EnBullet b)
    {
        if (b.x <= 0) { enbl.Remove(b); return; }
        b.x -= 2 * DT;
    }

    private void DrawEnBullet(EnBullet b) =>
        A.rectfill((int)b.x, (int)b.y, (int)(b.x + 2), (int)(b.y + 2), 8);

    // ===================== PARTICLES =====================

    private void PrtDraw(List<Ptcl> list)
    {
        foreach (var p in list)
            A.circfill((int)p.x, (int)p.y, (int)p.rad, (int)p.clr);
    }

    private void DrawCloseStar()
    {
        if (str2 != null)
            A.spr(str2.spt, (int)str2.x, (int)str2.y, str2.size, str2.size);
    }

    private void VcmMake()
    {
        for (int i = 0; i < 100; i++)
            vcm.Add(new Ptcl
            {
                x = (float)A.flr(A.rnd(148f)) - 20,
                y = (float)A.flr(A.rnd(148f)) - 20,
                dx = 1, dy = 1, act = 30,
                clr = RndPick(new float[] { 2, 7, 14 })
            });
    }

    private void UpdateVcm()
    {
        foreach (var p in vcm.ToList())
        {
            if (p.x < 64) p.x += p.dx * 2;
            if (p.x > 64) p.x -= p.dx * 2;
            if (p.y < 64) p.y += p.dy * 2;
            if (p.y > 64) p.y -= p.dy * 2;
            if (p.x == 64 || p.y == 64) p.act = -1;
            p.act--;
            if (p.act < 0) vcm.Remove(p);
        }
    }

    private void RctMake(float x, float y)
    {
        for (int i = 0; i < 4; i++)
            rct.Add(new Ptcl
            {
                x = x - (float)A.flr(A.rnd(5f)),
                y = y + (float)A.flr(A.rnd(10f)),
                dx = -2 - (float)A.flr(A.rnd(3f)),
                rad = (float)A.flr(A.rnd(2f)),
                act = 8, clr = 8
            });
    }

    private void UpdateRct()
    {
        foreach (var p in rct.ToList())
        {
            p.y += p.dy * 1.5f;
            if (p.act <= 8) p.clr = 8;
            if (p.act <= 6) p.clr = 9;
            if (p.act <= 3) p.clr = 10;
            p.act--;
            if (p.act < 0) rct.Remove(p);
        }
    }

    private void StrMake()
    {
        for (int i = 0; i < 16 - str.Count; i++)
        {
            float v = (float)A.flr(A.rnd(2f));
            str.Add(new Ptcl
            {
                x = 128 + (float)A.flr(A.rnd(128f)),
                y = 16 + A.rnd(100f),
                dx = 1 + v / 2,
                clr = 6 + v
            });
        }

        if (str2 == null)
        {
            int ri = A.rnd(3);
            str2 = new CloseStar
            {
                x = 256 + (float)A.flr(A.rnd(256f)),
                y = -100 + (float)A.flr(A.rnd(300f)),
                dx = 3,
                spt = StrSpts[ri].spt,
                size = StrSpts[ri].size
            };
        }
    }

    private void UpdateStr()
    {
        foreach (var p in str.ToList())
        {
            p.x -= p.dx;
            if (p.x < 0) str.Remove(p);
        }
        if (str2 != null) { str2.x -= str2.dx; if (str2.x < -300) str2 = null; }
    }

    private void PrtMake(float x, float y)
    {
        for (int i = 0; i < 30; i++)
            prt.Add(new Ptcl
            {
                x = x, y = y,
                dx = (float)A.flr(A.rnd(2f)) - 1,
                dy = (float)A.flr(A.rnd(2f)) - 1,
                rad = (float)A.flr(A.rnd(2f)),
                act = 6,
                clr = 5 + (float)A.flr(A.rnd(2f))
            });
    }

    private void UpdatePrt()
    {
        foreach (var p in prt.ToList())
        {
            p.x += p.dx * 2;
            p.y += p.dy * 2;
            p.act--;
            if (p.act < 0) prt.Remove(p);
        }
    }

    // ===================== RESTART =====================

    private void Restart()
    {
        youlose = true;
        VcmMake();
        A.sfx(3);
    }

    private void IntRest()
    {
        barValue = 0; shakeIntensity = 0; shakeDuration = 0;
        youlose = false; restartimer = 30; ltmr = 0;
        it = null;
        ittmr = 1028 + A.rnd(1028);
        p = new Player();
        prt = new(); str = new(); str2 = null; rct = new(); vcm = new();
        e = new(); enbl = new();
        enstpt = 1;
        entmr = 64 + A.rnd(64);
        score = 0; level = 1; finish = false; shields = 5;
        badgetmr = 60; finishtmr = 120;
    }

    private void UpdtRest()
    {
        restartimer--;
        if (restartimer == 0) IntRest();
    }

    // ===================== SCREEN SHAKE =====================

    private void ShakeScreen(float intensity, float duration)
    {
        shakeIntensity = intensity;
        shakeDuration = duration;
    }

    private (float sx, float sy) GetShakeOffset()
    {
        if (shakeDuration > 0)
        {
            shakeDuration--;
            return (
                (float)A.flr(A.rnd(shakeIntensity * 2)) - shakeIntensity,
                (float)A.flr(A.rnd(shakeIntensity * 2)) - shakeIntensity
            );
        }
        return (0, 0);
    }

    // ===================== ITEMS =====================

    private void UpdateItem()
    {
        if (ittmr > 0)
        {
            ittmr--;
            if (it != null) it.x--;
            return;
        }
        ittmr = 1028 + A.rnd(512);
        int sprite = p.l == 3 ? 35 : 34;
        if (sprite == 35 && p.pwr > 0) return;
        if (it == null || it.x < -8)
            it = new Item
            {
                s = sprite,
                x = 128 + (float)A.flr(A.rnd(128f)),
                y = 16 + (float)A.flr(A.rnd(80f))
            };
    }

    private void DrawItem() { if (it != null) A.spr(it.s, (int)it.x, (int)it.y); }

    // ===================== INTRO =====================

    private void InitIntro()
    {
        introoption = true; inttmrs = 30; countcoverart = 60;
        blink = false; blinkTimer = 0; done = false; info = false;
    }

    private void UpdateIntro()
    {
        if (countcoverart > 0) { countcoverart -= DT; return; }
        if (done) { MoveToGame(); return; }

        if (A.btn(5) && A.btn(1)) { info = true; blink = false; blinkTimer = 0; done = false; return; }

        if (info)
        {
            if (A.btn(5) && A.btn(0)) info = false;
            return;
        }

        if (blink)
        {
            blinkTimer -= DT;
            if (blinkTimer <= 0) { blink = false; done = true; return; }
        }

        if (inttmrs > 0) inttmrs -= DT;
        else { inttmrs = 30; StrMake(); }

        UpdateStr();

        if (!blink && A.btn(4))
        {
            A.sfx(5);
            blink = true;
            blinkTimer = BlinkDuration;
            done = false;
        }
    }

    private void DrawIntro()
    {
        if (countcoverart > 0)
        {
            A.map(0, 0, 0, 0, 16, 16);
            A.spr(128, 40, 16, 8, 8);
            Printol("   last pilot", 41, 16 + 64 + 8, 10, 8);
            Printol("by roberto freire", 41, 16 + 64 + 24, 10, 8);
            return;
        }

        if (info)
        {
            A.print("earth is under attack!", 0, 20, 10);
            A.print("you're the last aircraft pilot", 0, 30, 10);
            A.rectfill(0, 48, 128, 66, 6);
            A.print("  use x to shoot", 0, 50, 5);
            A.print("  use o to activate shield", 0, 60, 5);
            A.print("o + left (go back)", 30, 90, 6);
            return;
        }

        PrtDraw(str);
        A.spr(1, 56, 56, 2, 2);
        DrawCloseStar();

        int clr = (int)blinkTimer % 10 < 5 ? 6 : 5;
        A.print("press x to start", 30, 90, clr);
        A.print("o + right (info)", 38, 100, 6);
        A.print("max rank:", 48, 8, 6);
        var txt = NamesByLevel[maxlevel - 1];
        A.print(txt, 50 + 2 * (7 - txt.Length), 16, 13 - maxlevel);
    }

    private void MoveToGame()
    {
        introoption = false;
        gametmr = 5;
    }

    private void Printol(string t, int x, int y, int c1, int c2)
    {
        A.print(t, x, y + 1, c2);
        A.print(t, x, y, c1);
    }

    // ===================== SCORE =====================

    private void UpdateScore()
    {
        if (score > level * 3 + 5)
        {
            score = 0;
            level++;
            badgetmr = 60;
            if (level > maxlevel) maxlevel = level;
        }
        if (level > 5) finish = true;
    }

    private void DrawScore()
    {
        int clrlevel = 13 - level;
        A.pal(15, clrlevel);
        A.spr(50, 100, 0);
        if (badgetmr > 0)
        {
            badgetmr--;
            var txt = NamesByLevel[Math.Min(level - 1, NamesByLevel.Length - 1)];
            A.print(txt, 99 + 2 * (7 - txt.Length), 108, clrlevel);
            A.spr(64, 96, 96, 4, 4);
        }
        A.pal();
        PrtTxt(score, 110, 2, clrlevel);
    }

    private void PrtTxt(int n, int x, int y, int col)
    {
        var s = "0" + n;
        A.print(s.Substring(s.Length - 2), x, y, col);
    }

    // ===================== HUD =====================

    private void DrawHud()
    {
        if (ltmr > 0) { ltmr--; A.pal(6, 8); A.pal(5, 8); }
        for (int i = 1; i <= p.l; i++)
            A.spr(16, (i - 1) * 10, 0);
        A.pal();
        A.spr(51, 50, 0);
        A.print(shields.ToString(), 60, 2, 12);
    }

    // ===================== BAR =====================

    private void DrawBar()
    {
        float fillWidth = barValue / 1000f * (118 - 10);
        A.rectfill(1, 12, (int)(1 + fillWidth), 14,
            (int)(11 - A.flr(A.max(0, (barValue - 21) / 20))));
    }

    // ===================== HELPERS =====================

    private static bool RectOverlap(HB hb1, float x1, float y1, HB hb2, float x2, float y2)
    {
        float ax = x1 + hb1.X, ay = y1 + hb1.Y;
        float bx = x2 + hb2.X, by = y2 + hb2.Y;
        return ax < bx + hb2.W && bx < ax + hb1.W &&
               ay < by + hb2.H && by < ay + hb1.H;
    }

    private T RndPick<T>(T[] arr) => arr[A.rnd(arr.Length)];
}
