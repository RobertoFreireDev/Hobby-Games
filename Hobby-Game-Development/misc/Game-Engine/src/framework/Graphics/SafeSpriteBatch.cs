using blackbox.Input;
using blackbox.Utils;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;

namespace blackbox.Graphics;

public class SafeSpriteBatch
{
    private SpriteBatch _spriteBatch;
    private bool _begun;
    private const string Draw_has_not_begun = "Invalid draw call. Draw has not begun.\nHints: \n- You probably tried to draw outside _draw() function.";

    public SafeSpriteBatch(SpriteBatch spriteBatch)
    {
        _spriteBatch = spriteBatch;
    }

    public void Begin(SpriteSortMode sort, BlendState blendState, SamplerState sampleState, Effect effect)
    {
        _spriteBatch.Begin(sort, blendState, sampleState, null, null, effect);
        _begun = true;
    }

    public void Begin(SamplerState samplerState)
    {
        _spriteBatch.Begin(samplerState: samplerState);
        _begun = true;
    }

    public void Begin(Effect effect)
    {
        _spriteBatch.Begin(effect: effect, samplerState: SamplerState.PointClamp, transformMatrix: Camera2D.GetViewMatrix());
        _begun = true;
    }

    public void Begin()
    {
        _spriteBatch.Begin(samplerState: SamplerState.PointClamp, transformMatrix: Camera2D.GetViewMatrix());
        _begun = true;
    }

    public void End()
    {
        _spriteBatch.End();
        _begun = false;
    }

    public void Draw(Texture2D texture, Rectangle destination, Rectangle source, Color color, SpriteEffects effects)
    {
        if (!_begun)
        {
            LuaError.SetError(Draw_has_not_begun);
            return;
        }
        _spriteBatch.Draw(texture, destination, source, color, 0f, Vector2.Zero, effects, 0f);
    }

    public void Draw(Texture2D texture, Rectangle dest, Rectangle source, Color color)
    {
        if (!_begun)
        {
            LuaError.SetError(Draw_has_not_begun);
            return;
        }
        _spriteBatch.Draw(texture, dest, source, color);
    }

    public void Draw(RenderTarget2D sceneTarget, Rectangle boxToDraw, Color white)
    {
        if (!_begun)
        {
            LuaError.SetError(Draw_has_not_begun);
            return;
        }
        _spriteBatch.Draw(sceneTarget, boxToDraw, white);
    }

    public void Draw(Texture2D pixelTexture, Rectangle rectangle, Color color)
    {
        if (!_begun)
        {
            LuaError.SetError(Draw_has_not_begun);
            return;
        }
        _spriteBatch.Draw(pixelTexture, rectangle, color);
    }

    public void Draw(Texture2D texture, Vector2 vector, Color color)
    {
        if (!_begun)
        {
            LuaError.SetError(Draw_has_not_begun);
            return;
        }
        _spriteBatch.Draw(texture, vector, null, color, 0f, new Vector2(0, 0), 1.0f, SpriteEffects.None, 0f);
    }

    public void Draw(Texture2D texture, Vector2 vector, Color color, SpriteEffects effects)
    {
        if (!_begun)
        {
            LuaError.SetError(Draw_has_not_begun);
            return;
        }
        _spriteBatch.Draw(texture, vector, null, color, 0f, new Vector2(0, 0), 1.0f, effects, 0f);
    }

    public void DrawMouse()
    {
        if (!_begun)
        {
            LuaError.SetError(Draw_has_not_begun);
            return;
        }
        _spriteBatch.Draw(GFW.MouseTextures[MouseInput.Current_Cursor], MouseInput.MousePosition(4), Color.White);
    }
}
