using blackbox.Utils;
using System;
using System.Linq;
using System.Text;

namespace blackbox.Sfx;

public class SfxPlayer
{
    private SfxData[] Data = new SfxData[Constants.SfxQty];

    public SfxPlayer()
    {
        for (int i = 0; i < Data.Length; i++)
        {
            Data[i] = new SfxData();
        }
        AudioLib.CreateSound();
    }

    public void SetNote(int index, int noteIndex, string note)
    {
        if (!IsValidIndex(index) || !IsValidNoteIndex(noteIndex) || !IsValidNoteString(note) || Data[index] is null)
        {
            return;
        }

        int pitchDigit = (note[0] - '0') * 10 + (note[1] - '0');
        int waveDigit = note[2] - '0';
        int volumeDigit = (note[3] - '0') * 10 + (note[4] - '0');

        pitchDigit = Math.Clamp(pitchDigit, Constants.MinPitch, Constants.MaxPitch);
        waveDigit = Math.Clamp(waveDigit, Constants.MinWave, Constants.MaxWave);
        volumeDigit = Math.Clamp(volumeDigit, Constants.MinVolume, Constants.MaxVolume);

        Data[index].Notes[noteIndex] = new Note
        {
            Pitch = pitchDigit,
            Wave = (Waveform)waveDigit,
            Volume = volumeDigit / 10f
        };
    }

    public void SetSfx(int index, string sound)
    {
        sound = CleanNotes(sound);
        if (!IsValidIndex(index) || !IsValidSoundString(sound))
        {
            return;
        }

        int noteCount = (sound.Length - Constants.SpeedDigits) / Constants.CharsPerNote;
        for (int i = 0; i < Math.Min(noteCount, Constants.MaxNotes); i++)
        {
            SetNote(index, i, sound.Substring(i * Constants.CharsPerNote, Constants.CharsPerNote));
        }

        Data[index].Speed = int.Parse(sound.Substring(noteCount * Constants.CharsPerNote, 2));
    }

    private string CleanNotes(string sound)
    {
        if (sound.Length < 2)
            return sound;

        string speed = sound.Substring(sound.Length - 2, 2);
        string notesPart = sound.Substring(0, sound.Length - 2);
        var groups = Enumerable.Range(0, notesPart.Length / 5)
            .Select(i => notesPart.Substring(i * 5, 5))
            .Where(g => g != "00000");
        return string.Concat(groups) + speed;
    }

    public bool IsValidNoteString(string sound)
    {
        if (string.IsNullOrEmpty(sound) || sound.Length != Constants.CharsPerNote)
            return false;

        int pitch;
        int wave;
        int volume;

        if (!int.TryParse(sound.Substring(0, 2), out pitch))
            return false;
        if (!int.TryParse(sound.Substring(2, 1), out wave))
            return false;
        if (!int.TryParse(sound.Substring(3, 2), out volume))
            return false;

        if (pitch < Constants.MinPitch || pitch > Constants.MaxPitch)
            return false;
        if (wave < Constants.MinWave || wave > Constants.MaxWave)
            return false;
        if (volume < Constants.MinVolume || volume > Constants.MaxVolume)
            return false;

        return true;
    }

    public bool IsValidSoundString(string sound)
    {
        if (string.IsNullOrEmpty(sound))
            return false;

        int notesLength = (sound.Length - Constants.SpeedDigits);

        if (notesLength % Constants.CharsPerNote != 0)
            return false;

        int noteCount = notesLength / Constants.CharsPerNote;

        if (noteCount > Constants.MaxNotes)
        {
            return false;
        }

        int speed;
        for (int i = 0; i < noteCount; i++)
        {
            if (!IsValidNoteString(sound.Substring(i * Constants.CharsPerNote, Constants.CharsPerNote)))
            {
                return false;
            }
        }

        if (!int.TryParse(sound.Substring(noteCount * Constants.CharsPerNote, 2), out speed))
            return false;

        return true;
    }

    public void ConvertStringToData(string sounds)
    {
        var data = sounds.Split('\n');
        for (int i = 0; i < data.Length; i++)
        {
            SetSfx(i, data[i].TrimEnd());
        }
    }

    public StringBuilder GetSfx(int i, StringBuilder sb)
    {
        for (int j = 0; j < Constants.MaxNotes; j++)
        {
            if (Data[i]?.Notes?[j] is not null)
            {
                var note = Data[i].Notes[j];

                int pitch = note.Pitch;
                int wave = (int)note.Wave;
                int volume = (int)Math.Round(note.Volume * 10f);

                sb.Append(pitch.ToString("D2"));
                sb.Append(wave);
                sb.Append(volume.ToString("D2"));
            }
        }

        sb.Append(Data[i].Speed.ToString("D2"));

        return sb;
    }

    public string ConvertDataToString()
    {
        var sb = new StringBuilder();
        for (int i = 0; i < Data.Length; i++)
        {
            sb = GetSfx(i, sb);
            if (i < Data.Length - 1)
            {
                sb.Append("\n");
            }
        }
        return sb.ToString();
    }

    private bool IsValidIndex(int index)
    {
        return index >= 0 && index < Constants.SfxQty;
    }

    private bool IsValidNoteIndex(int index)
    {
        return index >= 0 && index < Constants.MaxNotes;
    }


    public void SetSpeed(int index, int speed = 1)
    {
        if (!IsValidIndex(index))
        {
            return;
        }

        var sfx = Data[index];
        sfx.Speed = Math.Clamp(speed, Constants.MinSpeed, Constants.MaxSpeed);
    }

    public void PlaySfx(int index)
    {
        if (!IsValidIndex(index))
        {
            return;
        }

        var sfx = Data[index];
        AudioLib.Play(sfx);
    }
}