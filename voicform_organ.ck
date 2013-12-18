false => int showButtonEvents;
false => int showMidiNotes;

Hid keyboard;
HidMsg keyMsg;

0 => int device;
if (!keyboard.openKeyboard(device))
	me.exit();
<<< "keyboard \""+keyboard.name()+"\" ready", "(device"+device+")" >>>;


Pan2 master => dac;
1 => master.gain;
VoicFormOrgan organ;

48 => int octaveRoot;


organ.choose_preset(1);
organ.show_controls();

while (true)
	{
	keyboard => now;

	while (keyboard.recv(keyMsg))
		{
		if (keyMsg.isButtonDown())
			{
			if (showButtonEvents)
				<<< "down:", keyMsg.which, "(code)", keyMsg.key, "(usb key)", keyMsg.ascii, "(ascii)" >>>;

			key_to_note(keyMsg.ascii) => int note;
			if (note >= 0)
				organ.note_on(note);
			else if ((keyMsg.ascii >= '0') && (keyMsg.ascii <= '9'))
				{
				organ.choose_preset(keyMsg.ascii-'0');
				organ.show_controls();
				}
			else if (keyMsg.ascii == '.')
				{
				organ.choose_preset(10);
				organ.show_controls();
				}
			else if (keyMsg.ascii == '-')
				{
				if (octaveRoot >= 12) octaveRoot-12 => octaveRoot;
				<<< "octave base is midi#",octaveRoot >>>;
				}
			else if (keyMsg.ascii == '=')
				{
				if (octaveRoot <= 98) octaveRoot+12 => octaveRoot;
				<<< "octave base is midi#",octaveRoot >>>;
				}
			else if (keyMsg.ascii == '`')
				{
				organ.generate_new_controls();
				organ.show_controls();
				}
			}
		else if (keyMsg.isButtonUp())
			{
			if (showButtonEvents)
				<<< "up:  ", keyMsg.which, "(code)", keyMsg.key, "(usb key)", keyMsg.ascii, "(ascii)" >>>;
			key_to_note(keyMsg.ascii) => int note;
			if (note >= 0)
				organ.note_off(note);
			}
		}
	}


fun int key_to_note(int key)
	{
	['A','S','D','F','G','H','J','K','L',';','\'','W','E','T','Y','U','O','P'] @=> int pianoKeys[];
    [  0,  2,  4,  5,  7,  9, 11, 12, 14, 16, 17 ,  1,  3,  6,  8, 10, 13, 15] @=> int pianoNotes[];

	-1 => int note;
	for (0=>int ix ; ix<pianoKeys.cap() ; ix++)
		{ if (pianoKeys[ix] == key) octaveRoot + pianoNotes[ix] => note; }
	return note;
	}


class VoicFormOrgan
	{
	VoicForm voice1 => JCRev reverb => master;
	VoicForm voice2 =>       reverb;
	VoicForm voice3 =>       reverb;
	VoicForm voice4 =>       reverb;
	VoicForm voice5 =>       reverb;

	[voice1,voice2,voice3,voice4,voice5] @=> VoicForm voices[];
	int voiceNote[voices.cap()];
	for (0=>int voiceIx ; voiceIx<voiceNote.cap() ; voiceIx++)
		{
		0 => voices[voiceIx].gain;
		-1 => voiceNote[voiceIx];
		}

	int   phonemeNum;
	float voiceMix;
	float loudness;
	float pitchSweepRate;
	float vibratoFreq;
	float vibratoGain;
	float revGain;
	float revMix;

	// phoneme   voice   loud    sweep   vFreq    vGain   rGain  rMix
	[/*0*/[  0. , .0000 , .0504 , .9037 , 5.5909 , .2094 , .8   , .2 ],
	 /*1*/[  3. , .0000 , .6281 , .7054 , 6.3622 , .0487 , .8   , .2 ],  
	 /*2*/[  3. , .0000 , .6374 , .9388 , 5.9242 , .0544 , .8   , .2 ],
	 /*3*/[  5. , .0000 , .6440 , .6141 , 7.9415 , .0448 , .8   , .2 ],
	 /*4*/[  9. , .0000 , .6862 , .1429 , 8.7406 , .0044 , .8   , .2 ],
	 /*5*/[ 16. , .0000 , .6000 , .3000 , 6.0000 , .1000 , .8   , .2 ],
	 /*6*/[ 16. , .0000 , .6003 , .4726 , 6.7799 , .1393 , .8   , .2 ],
	 /*7*/[ 17. , .0000 , .9703 , .1151 , 9.0939 , .0850 , .8   , .2 ],
	 /*8*/[ 19. , .0000 , .9999 , .9139 , 9.0046 , .0186 , .8   , .2 ],
	 /*9*/[ 31. , .0000 , .1157 , .0913 , 9.7343 , .0196 , .8   , .2 ],
	 /*.*/[  1. , .0000 , .6752 , .9424 , 5.0779 , .2113 , .8   , .2 ]]
	   @=> float presets[][];

	fun void note_on(int note)
		{
		for (0=>int scanIx ; scanIx<voiceNote.cap() ; scanIx++)
			{ if (voiceNote[scanIx] == note) return; }

		-1 => int voiceIx;
		for (0=>int scanIx ; scanIx<voiceNote.cap() ; scanIx++)
			{ if (voiceNote[scanIx] == -1) scanIx => voiceIx; }

		if (voiceIx == -1) return;

		note => voiceNote[voiceIx];

		phonemeNum     => voices[voiceIx].phonemeNum;
		voiceMix       => voices[voiceIx].voiceMix;
		loudness       => voices[voiceIx].loudness;
		pitchSweepRate => voices[voiceIx].pitchSweepRate;
		vibratoFreq    => voices[voiceIx].vibratoFreq;
		vibratoGain    => voices[voiceIx].vibratoGain;
		revGain        => reverb.gain;
		revMix         => reverb.mix;

		if (showMidiNotes)
			<<< "midi note:",note >>>;

		0.35 => voices[voiceIx].gain;
		note => Std.mtof => voices[voiceIx].freq;
		1 => voices[voiceIx].noteOn;
		}


	fun void note_off(int note)
		{
		-1 => int voiceIx;
		for (0=>int scanIx ; scanIx<voiceNote.cap() ; scanIx++)
			{ if (voiceNote[scanIx] == note) scanIx => voiceIx; }

		if (voiceIx >= 0)
			{
			-1 => voiceNote[voiceIx];
			1 => voices[voiceIx].noteOff;
			}

		return;
		}


	fun void choose_preset(int preset)
		{
		if (preset < presets.cap())
			{
			presets[preset][0] $ int => phonemeNum;
			presets[preset][1]       => voiceMix;
			presets[preset][2]       => loudness;
			presets[preset][3]       => pitchSweepRate;
			presets[preset][4]       => vibratoFreq;
			presets[preset][5]       => vibratoGain;
			presets[preset][6]       => revGain;
			presets[preset][7]       => revMix;
			}
		else
			<<< "preset "+preset+" ignored", "" >>>;
		}

	fun void generate_new_controls()
		{
		generate_new_phoneme();
		generate_new_voice_mix();
		generate_new_loudness();
		generate_new_pitch_sweep();
		generate_new_vibrato_freq();
		generate_new_vibrato_gain();
		}

	fun void generate_new_phoneme()      { (0,31) => Math.random2 => phonemeNum; }
	fun void generate_new_voice_mix()    { 0 => voiceMix; }
	fun void generate_new_loudness()     { Math.randomf() => loudness; }
	fun void generate_new_pitch_sweep()  { Math.randomf() => pitchSweepRate; }
	fun void generate_new_vibrato_freq() { (5.0,10.0) => Math.random2f => vibratoFreq; }
	fun void generate_new_vibrato_gain() { (.0,.3) => Math.random2f => vibratoGain; }

	fun void show_controls()
		{
		<<< "===== current controls =====","" >>>;
		<<< "phonemeNum= "+phonemeNum,"" >>>;
		<<< "voiceMix=   "+voiceMix,"" >>>;
		<<< "loudness=   "+loudness,"" >>>;
		<<< "pitchSweep= "+pitchSweepRate,"" >>>;
		<<< "vibratoFreq="+vibratoFreq,"" >>>;
		<<< "vibratoGain="+vibratoGain,"" >>>;
		<<< "revGain=    "+revGain,"" >>>;
		<<< "revMix=     "+revMix,"" >>>;
		}

	}
