//
//  FilterBank.m
//  HearingAid
//
//  Created by Hai Le on 19/3/14.
//  Copyright (c) 2014 Hai Le. All rights reserved.
//

#import "FilterBank.h"
#import "FDWaveformView.h"
#import "AMDataPlot.h"
#import "EAFUtilities.h"

@implementation FilterBank

@synthesize frames = _frames;

- (id)initWithFrames:(int)frames filterType:(int)bankIndex data:(float*)data
{
    self = [super init];
    if (self) {
        _frames = frames;
        _originalData = data;
    
        // Switch by bankIndex
        if (bankIndex == 1) {
            _filter = new Dsp::SmoothedFilterDesign<Dsp::Butterworth::Design::LowPass<6>, 1> (1024);
            
            Dsp::Params params;
            params[0] = 44100;  // sample rate
            params[1] = 6;      // order
            params[2] = 200;    // cutoff frequency
            _filter->setParams (params);
        }
        if (bankIndex == 2) {
            _filter = new Dsp::SmoothedFilterDesign<Dsp::Butterworth::Design::BandPass<6>, 1> (1024);
            
            Dsp::Params params;
            params[0] = 44100;  // sample rate
            params[1] = 6;      // order
            params[2] = 300;    // cutoff frequency
            params[3] = 100;    // band width
            _filter->setParams (params);
        }
        if (bankIndex == 3) {
            _filter = new Dsp::SmoothedFilterDesign<Dsp::Butterworth::Design::BandPass<6>, 1> (1024);
            
            Dsp::Params params;
            params[0] = 44100;  // sample rate
            params[1] = 6;      // order
            params[2] = 600;    // cutoff frequency
            params[3] = 200;    // band width
            _filter->setParams (params);
        }
        if (bankIndex == 4) {
            _filter = new Dsp::SmoothedFilterDesign<Dsp::Butterworth::Design::BandPass<6>, 1> (1024);
            
            Dsp::Params params;
            params[0] = 44100;  // sample rate
            params[1] = 6;      // order
            params[2] = 1200;    // cutoff frequency
            params[3] = 400;    // band width
            _filter->setParams (params);
        }
        if (bankIndex == 5) {
            _filter = new Dsp::SmoothedFilterDesign<Dsp::Butterworth::Design::BandPass<6>, 1> (1024);
            
            Dsp::Params params;
            params[0] = 44100;  // sample rate
            params[1] = 6;      // order
            params[2] = 2400;    // cutoff frequency
            params[3] = 1200;    // band width
            _filter->setParams (params);
        }
        if (bankIndex == 6) {
            _filter = new Dsp::SmoothedFilterDesign<Dsp::Butterworth::Design::HighPass<6>, 1> (1024);
            
            Dsp::Params params;
            params[0] = 44100;  // sample rate
            params[1] = 6;      // order
            params[2] = 3200;    // cutoff frequency
            _filter->setParams (params);
        }
        
        // Alloc filter array
        _filteredData = AllocateAudioBuffer(_frames);
        
        // Alloc low pass filter
        _lpFilter = new Dsp::SmoothedFilterDesign<Dsp::Butterworth::Design::LowPass<6>, 1> (1024);
        
        Dsp::Params params;
        params[0] = 44100;  // sample rate
        params[1] = 6;      // order
        params[2] = 10;    // cutoff frequency
        _lpFilter->setParams (params);
        
        // Alloc low sample-rate array
        _filteredData16 = new float[_frames/REDUCED_SAMPLE_RATE_TIME];
        _autocorrData = new float[AUTOCORR_SAMPLE_RATE * SECONDS_TO_ANALYZE];
    }
    return self;
}

- (void)process {
    // Step 1
    int frames16 = _frames/REDUCED_SAMPLE_RATE_TIME;
    
    ClearAudioBuffer(_filteredData, _frames);
    CopyAudioBuffer(_originalData, _filteredData, _frames);
    
    // Step 1
    _filter->reset();
    _filter->process(_frames, &_filteredData);
    
    
    // Step 2
    for (int frame = 0; frame<_frames; frame++) {
        _filteredData[frame] = fabsf(_filteredData[frame]);
    }
    _lpFilter->reset();
    _lpFilter->process(_frames, &_filteredData);
    
    // Step 3
    float max = 0.0;
    float foo = 0.0;
    ClearAudioBuffer(_filteredData16, frames16);
    for (int i = 1; i < frames16; i++) {
        foo = _filteredData[i*REDUCED_SAMPLE_RATE_TIME]-_filteredData[(i-1)*REDUCED_SAMPLE_RATE_TIME];
        if (foo > max) {
            max = foo;
        }
        _filteredData16[i] = MAX(0,foo);
    }
    max = max * max;
    // Autocorrelation
    ClearAudioBuffer(_autocorrData, AUTOCORR_SAMPLE_RATE * SECONDS_TO_ANALYZE);
    int size = AUTOCORR_SAMPLE_RATE * SECONDS_TO_ANALYZE;
    for (int m = 0; m < size; m++) {
        float sum = 0;
        for (int n = 0; n < frames16-m ; n++) {
            sum += (_filteredData16[n] * _filteredData16[n+m] / max) ;
        }
        _autocorrData[m] = sum;
    }
    
    [self.delegate didFinishCalculateData];
}

- (float)getSampleRate {
    return AUTOCORR_SAMPLE_RATE;
}
- (int)getFrames {
    return AUTOCORR_SAMPLE_RATE * SECONDS_TO_ANALYZE;
}
- (float*)getAutocorrData {
    return _autocorrData;
}

@end
