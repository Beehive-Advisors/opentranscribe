#!/usr/bin/env python3
"""Test script to validate faster-whisper turbo runs on GPU locally.

This script validates Step 3.1 from plan.md:
- Install GPU PyTorch
- Install CUDA libs and faster-whisper
- Test that turbo model runs on GPU
"""
import sys
import os

def test_gpu_available():
    """Check if CUDA is available."""
    try:
        import torch
        cuda_available = torch.cuda.is_available()
        if cuda_available:
            print(f"✅ CUDA is available")
            print(f"   Device: {torch.cuda.get_device_name(0)}")
            print(f"   CUDA Version: {torch.version.cuda}")
            return True
        else:
            print("❌ CUDA is not available")
            return False
    except ImportError:
        print("❌ PyTorch not installed")
        return False


def test_faster_whisper():
    """Test faster-whisper with turbo model."""
    try:
        from faster_whisper import WhisperModel
        print("\n🔄 Loading WhisperModel with turbo model...")
        
        model = WhisperModel("turbo", device="cuda", compute_type="float16")
        print("✅ Model loaded successfully")
        
        # Test with a dummy transcription (if you have a test file)
        # For now, just verify model loads
        print("✅ GPU validation complete - model can run on GPU")
        return True
        
    except ImportError:
        print("❌ faster-whisper not installed")
        print("   Install with: pip install faster-whisper")
        return False
    except Exception as e:
        print(f"❌ Error loading model: {e}")
        return False


def main():
    """Run GPU validation tests."""
    print("=" * 60)
    print("OpenTranscribe - Local GPU Validation Test")
    print("=" * 60)
    
    # Test 1: CUDA availability
    if not test_gpu_available():
        print("\n❌ GPU validation failed - CUDA not available")
        sys.exit(1)
    
    # Test 2: faster-whisper
    if not test_faster_whisper():
        print("\n❌ GPU validation failed - faster-whisper test failed")
        sys.exit(1)
    
    print("\n" + "=" * 60)
    print("✅ All GPU validation tests passed!")
    print("=" * 60)


if __name__ == "__main__":
    main()

