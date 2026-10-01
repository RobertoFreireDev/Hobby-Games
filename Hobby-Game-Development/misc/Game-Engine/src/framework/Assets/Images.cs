using blackbox.Utils;
using Microsoft.Xna.Framework.Graphics;
using System.Collections.Generic;

namespace blackbox.Assets;

public static class Images
{
    private static readonly Dictionary<string, string> Base64Images = new Dictionary<string, string>
    {
        {
            "mouse",
            "iVBORw0KGgoAAAANSUhEUgAAACAAAAAQCAMAAABA3o1rAAAAAXNSR0IArs4c6QAAAGBQTFRFAAAAIiA0RSg8Zjkxj1Y733Em2aBm7sOa+/I2meVQar4wN5RuS2kvUkskMjw5Pz90MGCCW27hY5v/X83ky9v8////m623hH6HaWpqWVZSdkKKrDIy2Vdj13u6j5dKim8w+2O8zwAAACB0Uk5TAP////////////////////////////////////////+Smq12AAAAYUlEQVQokYXQwQ0AIQhE0flF0H+rmyUKAiZykvFBjJIkVAvoQW3NrCe8QAkcMJLW/qYkxgBJHGwBCSKzFH4TYIkFvNvnIzpCHoC5gvGGJm7gFDkD1xUxQ/lv+n38UJ5WSR/3yQ8jxP7YwAAAAABJRU5ErkJggg=="
        },
        {
            "medium_font",
            "iVBORw0KGgoAAAANSUhEUgAAAF8AAAAjCAYAAADyrNZPAAAAAXNSR0IArs4c6QAAAoJJREFUaIHtWsuOwyAMhGj//5fZS1MhrwdmbGijFXNqHPwCYztWSzn4GmoppbTW2ptQa71/t9aafbbrEK3WWnt+hXcHjfUj6m90D97E/mV7wZ6WXefRkDxGjiovQ/P0RWxm5dnnCznfR0DP6AlTDGL5WXkszfOHQcbnmV9w8xHqC+hZoRVwyEhvVN59/Rk9Hi+rm7Glx8/9A50ayvteHhtBSWHMOmUzR1E6qnFoHasDrcncxIODf4Zol2ALkFKQEO9MnsKr+BalsY1DD7ngsrBFrnV9r13n8c7kFVD8Ef9OeAWYCaLh5n+iMCgFFzm4yxb7kYTWIfvQ3t38FxJWhBYtc0BK29bbwvJl4N1W73ahIPX2rl93jRYigyLRhqII6WBaO8XmqC0sPHvYA3kUVqeTg4ODJ2HZKJahZcbMHu+oCxn54fGrvkV5ez+ufoHXKs0q9oh31qJ5nQPq1TMF8hPfHKwfPUJTTUtDBZJxTtG7u+1lfChOINyBpjYJf6aakSlftKXqP9XVKSmyhQFqNdHzrFWN2Hxw8HzsitZtg7XdGA2u7GbNBlxFyPcevU+fit4LMWdpn/hK9aaaKP/PahQCs9Gjmufpvd9Jkc9O+bIzEyUKI7IUmcxh3rJUv6cjZU+Bd+pel2Rps2uJHEM0BiM+dsjn8XjfDaptVxlEdAaZtKP027Nc7vErds1uOXqHDsmTuR2Z/P+t3pgtuFGcvy+ImBXakECUj2edjfe8GkivpbEpIWvvKn+HfxdcnZsYo71DZ7usLC1jdxioUK1Uim4SU5jROsbmkW8r9T4e0cj3eJVNRYcetXfp5q+OfDaiFXnWHja/e7Sn5PzT7YiwtSgj6xcaOqWkv64FWwAAAABJRU5ErkJggg=="
        }
    };

    public static Dictionary<string, Texture2D> GetAllImages()
    {
        var textures = new Dictionary<string, Texture2D>();

        foreach (var pair in Base64Images)
        {
            textures.Add(pair.Key, TextureUtils.Convert64ToTexture(pair.Value));
        }

        return textures;
    }
}
