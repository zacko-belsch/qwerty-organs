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
FluteOrgan organ;

72 => int octaveRoot;


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


class FluteOrgan
	{
	Flute voice1 => JCRev reverb => master;
	Flute voice2 =>       reverb;
	Flute voice3 =>       reverb;
	Flute voice4 =>       reverb;
	Flute voice5 =>       reverb;

	[voice1,voice2,voice3,voice4,voice5] @=> Flute voices[];
	int voiceNote[voices.cap()];
	for (0=>int voiceIx ; voiceIx<voiceNote.cap() ; voiceIx++)
		{
		0 => voices[voiceIx].gain;
		-1 => voiceNote[voiceIx];
		}

	float jetDelay;
	float jetReflection;
	float endReflection;
	float noiseGain;
	float vibratoFreq;
	float vibratoGain;
	float pressure;
	float rate;
	float revGain;
	float revMix;

	//      jDel    jRefl   eRefl   noise   vFreq    vGain   press   rate   rGain  rMix
	[/*0*/[ .3200 , .5000 , .5000 , .3750 , .4937  , .3750 , 1.000 , .0050 , .8 , .2 ], // stk defaults
	 /*1*/[ .2516 , .6464 , .1156 , .4502 , 8.1102 , .3000 , .7965 , .0305 , .8 , .2 ],
     /*2*/[ .9732 , .2331 , .7436 , .4077 , 7.8039 , .9114 , .5952 , .0050 , .8 , .2 ],
	 /*3*/[ .6704 , .7381 , .4772 , .8767 , 7.0829 , .4443 , .6822 , .5270 , .8 , .2 ],
	 /*4*/[ .6765 , .6822 , .4709 , .2276 , 2.5443 , .4637 , .5294 , .1870 , .8 , .2 ],
	 /*5*/[ .7303 , .8381 , .7584 , .9547 , 2.4163 , .8061 , .6780 , .2403 , .8 , .2 ], // broken caliope at 84+
	 /*6*/[ .0557 , .7377 , .3657 , .1000 , 11.318 , .4281 , .5861 , .5825 , .8 , .2 ],
	 /*7*/[ .4990 , .8210 , .8208 , .8543 , 4.9034 , .1526 , .0888 , .2114 , .8 , .2 ],
	 /*8*/[ .8565 , .7024 , .6666 , .6234 , 9.3077 , .6257 , .0668 , .4903 , .8 , .2 ], // squeaky
	 /*9*/[ .1203 , .1681 , .7092 , .9814 , 1.0600 , .1411 , .8454 , .4940 , .8 , .2 ], // unvoiced
	 /*.*/[ .0000 , .0000 , .0504 , .9037 , 5.5909 , .2094 , .2094 , .2094 , .8 , .2 ]] // footsteps!
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

		jetDelay      => voices[voiceIx].jetDelay;
		jetReflection => voices[voiceIx].jetReflection;
		endReflection => voices[voiceIx].endReflection;
		noiseGain     => voices[voiceIx].noiseGain;
		vibratoFreq   => voices[voiceIx].vibratoFreq;
		vibratoGain   => voices[voiceIx].vibratoGain;
		pressure      => voices[voiceIx].pressure;
		rate          => voices[voiceIx].rate;

		revGain       => reverb.gain;
		revMix        => reverb.mix;

		if (showMidiNotes)
			<<< "midi note:",note >>>;

		0.35 => voices[voiceIx].gain;
		note => Std.mtof => voices[voiceIx].freq;
		1 => voices[voiceIx].noteOn;  // should this be startBlowing?
		}


	fun void note_off(int note)
		{
		-1 => int voiceIx;
		for (0=>int scanIx ; scanIx<voiceNote.cap() ; scanIx++)
			{ if (voiceNote[scanIx] == note) scanIx => voiceIx; }

		if (voiceIx >= 0)
			{
			-1 => voiceNote[voiceIx];
			1 => voices[voiceIx].noteOff;  // should this be stopBlowing?
			1 => voices[voiceIx].stopBlowing;
			1 => voices[voiceIx].clear;
			}

		return;
		}


	fun void choose_preset(int preset)
		{
		if (preset < 0)
			{
			voices[0].jetDelay()      => jetDelay;
			voices[0].jetReflection() => jetReflection;
			voices[0].endReflection() => endReflection;
			voices[0].noiseGain()     => noiseGain;
			voices[0].vibratoFreq()   => vibratoFreq;
			voices[0].vibratoGain()   => vibratoGain;
			voices[0].pressure()      => pressure;
			voices[0].rate()          => rate;
			.8 => revGain;
			.2 => revMix;
			}
		else if (preset < presets.cap())
			{
			presets[preset][0] => jetDelay;
			presets[preset][1] => jetReflection;
			presets[preset][2] => endReflection;
			presets[preset][3] => noiseGain;
			presets[preset][4] => vibratoFreq;
			presets[preset][5] => vibratoGain;
			presets[preset][6] => pressure;
			presets[preset][7] => rate;
			presets[preset][8] => revGain;
			presets[preset][9] => revMix;
			}
		else
			<<< "preset "+preset+" ignored", "" >>>;
		}

	fun void generate_new_controls()
		{
		generate_new_jet_delay();
		generate_new_jet_reflection();
		generate_new_end_reflection();
		generate_new_noise_gain();
		generate_new_vibrato_freq();
		generate_new_vibrato_gain();
		generate_new_pressure();
		generate_new_rate();
		}

	fun void generate_new_jet_delay()      { (0,1)  => Math.random2f => jetDelay; }
	fun void generate_new_jet_reflection() { (0,1)  => Math.random2f => jetReflection; }
	fun void generate_new_end_reflection() { (0,1)  => Math.random2f => endReflection; }
	fun void generate_new_noise_gain()     { (0,1)  => Math.random2f => noiseGain; }
	fun void generate_new_vibrato_freq()   { (1,12) => Math.random2f => vibratoFreq; }
	fun void generate_new_vibrato_gain()   { (0,1)  => Math.random2f => vibratoGain; }
	fun void generate_new_pressure()       { (0,1)  => Math.random2f => pressure; }
	fun void generate_new_rate()           { (0,1)  => Math.random2f => rate; }

	fun void show_controls()
		{
		<<< "===== current controls =====","" >>>;
		<<< "jetDelay=     "+jetDelay,"" >>>;
		<<< "jetReflection="+jetReflection,"" >>>;
		<<< "endReflection="+endReflection,"" >>>;
		<<< "noiseGain=    "+noiseGain,"" >>>;
		<<< "vibratoFreq=  "+vibratoFreq,"" >>>;
		<<< "vibratoGain=  "+vibratoGain,"" >>>;
		<<< "pressure=     "+pressure,"" >>>;
		<<< "rate=         "+rate,"" >>>;
		<<< "revGain=      "+revGain,"" >>>;
		<<< "revMix=       "+revMix,"" >>>;
		}

	}
