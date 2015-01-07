/****************************************************************************
Copyright (c) 2010-2012 cocos2d-x.org

http://www.cocos2d-x.org

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
****************************************************************************/
package com.dangge.games.xinsanguozhi;

import org.cocos2dx.lib.Cocos2dxActivity;
import org.cocos2dx.lib.Cocos2dxGLSurfaceView;
import org.cocos2dx.lib.Cocos2dxLuaJavaBridge;

import android.app.Activity;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.net.ConnectivityManager;
import android.net.NetworkInfo;
import android.os.Bundle;
import android.view.WindowManager;

public class Xinsanguozhi extends Cocos2dxActivity {
	private static Activity instance = null;
	private static BroadcastReceiver sConnReceiver = null;

	@Override
	public void onCreate(Bundle savedInstanceState) {
		super.onCreate(savedInstanceState);
		 getWindow().addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);
		 
		 instance = this;
	}
	
	@Override
    public void onDestroy() {
		super.onDestroy();
		
		if (sConnReceiver != null) {
			unregisterReceiver(sConnReceiver);
		}
    }


    @Override
	public Cocos2dxGLSurfaceView onCreateView() {
		// TODO Auto-generated method stub
		//return super.onCreateView();
    	Cocos2dxGLSurfaceView glSurfaceView = new Cocos2dxGLSurfaceView(this); 
    	glSurfaceView.setEGLConfigChooser(5, 6, 5, 0, 16, 8); 
    	return glSurfaceView;
	}

    // 网络监测
  	public static void networkMonitor(){
  		sConnReceiver = new BroadcastReceiver() { 
  	        @Override 
  	        public void onReceive(Context context, Intent intent) {
  	        	 String action = intent.getAction();
  	             if (action.equals(ConnectivityManager.CONNECTIVITY_ACTION)) {
  	                 ConnectivityManager connectivityManager = (ConnectivityManager)instance.getSystemService(Context.CONNECTIVITY_SERVICE);
  	                 NetworkInfo info = connectivityManager.getActiveNetworkInfo();
  	                 if (info != null && info.isAvailable()) {
  	                	 Cocos2dxLuaJavaBridge.callLuaGlobalFunctionWithString("netchange", info.getTypeName());
  	                 } else {
  	                	 Cocos2dxLuaJavaBridge.callLuaGlobalFunctionWithString("netchange", "none");
  	                 }
  	             }    
  	        }
  	    };
  	    instance.registerReceiver(sConnReceiver, new IntentFilter(ConnectivityManager.CONNECTIVITY_ACTION));
  	}

	static {
    	System.loadLibrary("game");
    }
}
