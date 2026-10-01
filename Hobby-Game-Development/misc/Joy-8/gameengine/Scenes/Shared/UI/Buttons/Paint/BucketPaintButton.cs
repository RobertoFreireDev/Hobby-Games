using gameengine.Data;
using gameengine.Scenes.Shared.UI.Buttons.Effects;

namespace gameengine.Scenes.Shared.UI.Buttons.Paint;

internal class BucketPaintButton : PaintButton
{
    public BucketPaintButton(UIComponentEnum component)
        : base(new NoEffect(), PaintOptionEnum.Bucket, component, GameEngineData.Images["bucket_button"])
    {

    }
}

