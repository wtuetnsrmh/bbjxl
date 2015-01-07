/*
** Lua binding: talkingdata_luabinding
** Generated automatically by tolua++-1.0.92 on 12/25/13 22:29:43.
*/

#include "TalkingData.h"
#include "talkingdata_luabinding.h"
#include "CCLuaEngine.h"

using namespace cocos2d;





/* function to register type */
static void tolua_reg_types (lua_State* tolua_S)
{
 tolua_usertype(tolua_S,"TDCCMission");
 tolua_usertype(tolua_S,"TDCCVirtualCurrency");
 
 tolua_usertype(tolua_S,"TDCCTalkingDataGA");
 tolua_usertype(tolua_S,"TDCCItem");
 tolua_usertype(tolua_S,"TDCCAccount");
}

/* method: onChargeRequest of class  TDCCVirtualCurrency */
#ifndef TOLUA_DISABLE_tolua_talkingdata_luabinding_TDCCVirtualCurrency_onChargeRequest00
static int tolua_talkingdata_luabinding_TDCCVirtualCurrency_onChargeRequest00(lua_State* tolua_S)
{
#ifndef TOLUA_RELEASE
 tolua_Error tolua_err;
 if (
     !tolua_isusertable(tolua_S,1,"TDCCVirtualCurrency",0,&tolua_err) ||
     !tolua_isstring(tolua_S,2,0,&tolua_err) ||
     !tolua_isstring(tolua_S,3,0,&tolua_err) ||
     !tolua_isnumber(tolua_S,4,0,&tolua_err) ||
     !tolua_isstring(tolua_S,5,0,&tolua_err) ||
     !tolua_isnumber(tolua_S,6,0,&tolua_err) ||
     !tolua_isstring(tolua_S,7,0,&tolua_err) ||
     !tolua_isnoobj(tolua_S,8,&tolua_err)
 )
  goto tolua_lerror;
 else
#endif
 {
  const char* orderId = ((const char*)  tolua_tostring(tolua_S,2,0));
  const char* iapId = ((const char*)  tolua_tostring(tolua_S,3,0));
  double currencyAmount = ((double)  tolua_tonumber(tolua_S,4,0));
  const char* currencyType = ((const char*)  tolua_tostring(tolua_S,5,0));
  double virtualCurrencyAmount = ((double)  tolua_tonumber(tolua_S,6,0));
  const char* paymentType = ((const char*)  tolua_tostring(tolua_S,7,0));
  {
   TDCCVirtualCurrency::onChargeRequest(orderId,iapId,currencyAmount,currencyType,virtualCurrencyAmount,paymentType);
  }
 }
 return 0;
#ifndef TOLUA_RELEASE
 tolua_lerror:
 tolua_error(tolua_S,"#ferror in function 'onChargeRequest'.",&tolua_err);
 return 0;
#endif
}
#endif //#ifndef TOLUA_DISABLE

/* method: onChargeSuccess of class  TDCCVirtualCurrency */
#ifndef TOLUA_DISABLE_tolua_talkingdata_luabinding_TDCCVirtualCurrency_onChargeSuccess00
static int tolua_talkingdata_luabinding_TDCCVirtualCurrency_onChargeSuccess00(lua_State* tolua_S)
{
#ifndef TOLUA_RELEASE
 tolua_Error tolua_err;
 if (
     !tolua_isusertable(tolua_S,1,"TDCCVirtualCurrency",0,&tolua_err) ||
     !tolua_isstring(tolua_S,2,0,&tolua_err) ||
     !tolua_isnoobj(tolua_S,3,&tolua_err)
 )
  goto tolua_lerror;
 else
#endif
 {
  const char* orderId = ((const char*)  tolua_tostring(tolua_S,2,0));
  {
   TDCCVirtualCurrency::onChargeSuccess(orderId);
  }
 }
 return 0;
#ifndef TOLUA_RELEASE
 tolua_lerror:
 tolua_error(tolua_S,"#ferror in function 'onChargeSuccess'.",&tolua_err);
 return 0;
#endif
}
#endif //#ifndef TOLUA_DISABLE

/* method: onReward of class  TDCCVirtualCurrency */
#ifndef TOLUA_DISABLE_tolua_talkingdata_luabinding_TDCCVirtualCurrency_onReward00
static int tolua_talkingdata_luabinding_TDCCVirtualCurrency_onReward00(lua_State* tolua_S)
{
#ifndef TOLUA_RELEASE
 tolua_Error tolua_err;
 if (
     !tolua_isusertable(tolua_S,1,"TDCCVirtualCurrency",0,&tolua_err) ||
     !tolua_isnumber(tolua_S,2,0,&tolua_err) ||
     !tolua_isstring(tolua_S,3,0,&tolua_err) ||
     !tolua_isnoobj(tolua_S,4,&tolua_err)
 )
  goto tolua_lerror;
 else
#endif
 {
  double currencyAmount = ((double)  tolua_tonumber(tolua_S,2,0));
  const char* reason = ((const char*)  tolua_tostring(tolua_S,3,0));
  {
   TDCCVirtualCurrency::onReward(currencyAmount,reason);
  }
 }
 return 0;
#ifndef TOLUA_RELEASE
 tolua_lerror:
 tolua_error(tolua_S,"#ferror in function 'onReward'.",&tolua_err);
 return 0;
#endif
}
#endif //#ifndef TOLUA_DISABLE

/* method: onStart of class  TDCCTalkingDataGA */
#ifndef TOLUA_DISABLE_tolua_talkingdata_luabinding_TDCCTalkingDataGA_onStart00
static int tolua_talkingdata_luabinding_TDCCTalkingDataGA_onStart00(lua_State* tolua_S)
{
#ifndef TOLUA_RELEASE
 tolua_Error tolua_err;
 if (
     !tolua_isusertable(tolua_S,1,"TDCCTalkingDataGA",0,&tolua_err) ||
     !tolua_isstring(tolua_S,2,0,&tolua_err) ||
     !tolua_isstring(tolua_S,3,0,&tolua_err) ||
     !tolua_isnoobj(tolua_S,4,&tolua_err)
 )
  goto tolua_lerror;
 else
#endif
 {
  const char* appId = ((const char*)  tolua_tostring(tolua_S,2,0));
  const char* channelId = ((const char*)  tolua_tostring(tolua_S,3,0));
  {
   TDCCTalkingDataGA::onStart(appId,channelId);
  }
 }
 return 0;
#ifndef TOLUA_RELEASE
 tolua_lerror:
 tolua_error(tolua_S,"#ferror in function 'onStart'.",&tolua_err);
 return 0;
#endif
}
#endif //#ifndef TOLUA_DISABLE

/* method: onEvent of class  TDCCTalkingDataGA */
#ifndef TOLUA_DISABLE_tolua_talkingdata_luabinding_TDCCTalkingDataGA_onEvent00
static int tolua_talkingdata_luabinding_TDCCTalkingDataGA_onEvent00(lua_State* tolua_S)
{
#ifndef TOLUA_RELEASE
 tolua_Error tolua_err;
 if (
     !tolua_isusertable(tolua_S,1,"TDCCTalkingDataGA",0,&tolua_err) ||
     !tolua_isstring(tolua_S,2,0,&tolua_err) ||
     (tolua_isvaluenil(tolua_S,3,&tolua_err) || !toluafix_istable(tolua_S,3,"LUA_TABLE",0,&tolua_err)) ||
     !tolua_isnoobj(tolua_S,4,&tolua_err)
 )
  goto tolua_lerror;
 else
#endif
 {
	 const char* eventId = ((const char*)  tolua_tostring(tolua_S,2,0));
	 LUA_TABLE map = (  toluafix_totable(tolua_S,3,0));
	 {
		 EventParamMap eventParams;

		 lua_pushnil(tolua_S);
		 while (lua_next(tolua_S, 3))
		 {
			 lua_pushvalue(tolua_S, -2);
			 const char* key = lua_tostring(tolua_S, -1);
			 const char* value = lua_tostring(tolua_S, -2);
			 eventParams[key] = value;

			 lua_pop(tolua_S, 2);
		 }
		 TDCCTalkingDataGA::onEvent(eventId, &eventParams);
	 }
 }
 return 0;
#ifndef TOLUA_RELEASE
 tolua_lerror:
 tolua_error(tolua_S,"#ferror in function 'onEvent'.",&tolua_err);
 return 0;
#endif
}
#endif //#ifndef TOLUA_DISABLE

/* method: setLatitude of class  TDCCTalkingDataGA */
#ifndef TOLUA_DISABLE_tolua_talkingdata_luabinding_TDCCTalkingDataGA_setLatitude00
static int tolua_talkingdata_luabinding_TDCCTalkingDataGA_setLatitude00(lua_State* tolua_S)
{
#ifndef TOLUA_RELEASE
 tolua_Error tolua_err;
 if (
     !tolua_isusertable(tolua_S,1,"TDCCTalkingDataGA",0,&tolua_err) ||
     !tolua_isnumber(tolua_S,2,0,&tolua_err) ||
     !tolua_isnumber(tolua_S,3,0,&tolua_err) ||
     !tolua_isnoobj(tolua_S,4,&tolua_err)
 )
  goto tolua_lerror;
 else
#endif
 {
  double latitude = ((double)  tolua_tonumber(tolua_S,2,0));
  double longitude = ((double)  tolua_tonumber(tolua_S,3,0));
  {
   TDCCTalkingDataGA::setLatitude(latitude,longitude);
  }
 }
 return 0;
#ifndef TOLUA_RELEASE
 tolua_lerror:
 tolua_error(tolua_S,"#ferror in function 'setLatitude'.",&tolua_err);
 return 0;
#endif
}
#endif //#ifndef TOLUA_DISABLE

/* method: getDeviceId of class  TDCCTalkingDataGA */
#ifndef TOLUA_DISABLE_tolua_talkingdata_luabinding_TDCCTalkingDataGA_getDeviceId00
static int tolua_talkingdata_luabinding_TDCCTalkingDataGA_getDeviceId00(lua_State* tolua_S)
{
#ifndef TOLUA_RELEASE
 tolua_Error tolua_err;
 if (
     !tolua_isusertable(tolua_S,1,"TDCCTalkingDataGA",0,&tolua_err) ||
     !tolua_isnoobj(tolua_S,2,&tolua_err)
 )
  goto tolua_lerror;
 else
#endif
 {
  {
   const char* tolua_ret = (const char*)  TDCCTalkingDataGA::getDeviceId();
   tolua_pushstring(tolua_S,(const char*)tolua_ret);
  }
 }
 return 1;
#ifndef TOLUA_RELEASE
 tolua_lerror:
 tolua_error(tolua_S,"#ferror in function 'getDeviceId'.",&tolua_err);
 return 0;
#endif
}
#endif //#ifndef TOLUA_DISABLE

/* method: onKill of class  TDCCTalkingDataGA */
#ifndef TOLUA_DISABLE_tolua_talkingdata_luabinding_TDCCTalkingDataGA_onKill00
static int tolua_talkingdata_luabinding_TDCCTalkingDataGA_onKill00(lua_State* tolua_S)
{
#ifndef TOLUA_RELEASE
 tolua_Error tolua_err;
 if (
     !tolua_isusertable(tolua_S,1,"TDCCTalkingDataGA",0,&tolua_err) ||
     !tolua_isnoobj(tolua_S,2,&tolua_err)
 )
  goto tolua_lerror;
 else
#endif
 {
  {
   TDCCTalkingDataGA::onKill();
  }
 }
 return 0;
#ifndef TOLUA_RELEASE
 tolua_lerror:
 tolua_error(tolua_S,"#ferror in function 'onKill'.",&tolua_err);
 return 0;
#endif
}
#endif //#ifndef TOLUA_DISABLE

/* method: setVerboseLogEnabled of class  TDCCTalkingDataGA */
#ifndef TOLUA_DISABLE_tolua_talkingdata_luabinding_TDCCTalkingDataGA_setVerboseLogEnabled00
static int tolua_talkingdata_luabinding_TDCCTalkingDataGA_setVerboseLogEnabled00(lua_State* tolua_S)
{
#ifndef TOLUA_RELEASE
 tolua_Error tolua_err;
 if (
     !tolua_isusertable(tolua_S,1,"TDCCTalkingDataGA",0,&tolua_err) ||
     !tolua_isnoobj(tolua_S,2,&tolua_err)
 )
  goto tolua_lerror;
 else
#endif
 {
  {
   TDCCTalkingDataGA::setVerboseLogEnabled();
  }
 }
 return 0;
#ifndef TOLUA_RELEASE
 tolua_lerror:
 tolua_error(tolua_S,"#ferror in function 'setVerboseLogEnabled'.",&tolua_err);
 return 0;
#endif
}
#endif //#ifndef TOLUA_DISABLE

/* method: onPurchase of class  TDCCItem */
#ifndef TOLUA_DISABLE_tolua_talkingdata_luabinding_TDCCItem_onPurchase00
static int tolua_talkingdata_luabinding_TDCCItem_onPurchase00(lua_State* tolua_S)
{
#ifndef TOLUA_RELEASE
 tolua_Error tolua_err;
 if (
     !tolua_isusertable(tolua_S,1,"TDCCItem",0,&tolua_err) ||
     !tolua_isstring(tolua_S,2,0,&tolua_err) ||
     !tolua_isnumber(tolua_S,3,0,&tolua_err) ||
     !tolua_isnumber(tolua_S,4,0,&tolua_err) ||
     !tolua_isnoobj(tolua_S,5,&tolua_err)
 )
  goto tolua_lerror;
 else
#endif
 {
  const char* item = ((const char*)  tolua_tostring(tolua_S,2,0));
  int number = ((int)  tolua_tonumber(tolua_S,3,0));
  double price = ((double)  tolua_tonumber(tolua_S,4,0));
  {
   TDCCItem::onPurchase(item,number,price);
  }
 }
 return 0;
#ifndef TOLUA_RELEASE
 tolua_lerror:
 tolua_error(tolua_S,"#ferror in function 'onPurchase'.",&tolua_err);
 return 0;
#endif
}
#endif //#ifndef TOLUA_DISABLE

/* method: onUse of class  TDCCItem */
#ifndef TOLUA_DISABLE_tolua_talkingdata_luabinding_TDCCItem_onUse00
static int tolua_talkingdata_luabinding_TDCCItem_onUse00(lua_State* tolua_S)
{
#ifndef TOLUA_RELEASE
 tolua_Error tolua_err;
 if (
     !tolua_isusertable(tolua_S,1,"TDCCItem",0,&tolua_err) ||
     !tolua_isstring(tolua_S,2,0,&tolua_err) ||
     !tolua_isnumber(tolua_S,3,0,&tolua_err) ||
     !tolua_isnoobj(tolua_S,4,&tolua_err)
 )
  goto tolua_lerror;
 else
#endif
 {
  const char* item = ((const char*)  tolua_tostring(tolua_S,2,0));
  int number = ((int)  tolua_tonumber(tolua_S,3,0));
  {
   TDCCItem::onUse(item,number);
  }
 }
 return 0;
#ifndef TOLUA_RELEASE
 tolua_lerror:
 tolua_error(tolua_S,"#ferror in function 'onUse'.",&tolua_err);
 return 0;
#endif
}
#endif //#ifndef TOLUA_DISABLE

/* method: onBegin of class  TDCCMission */
#ifndef TOLUA_DISABLE_tolua_talkingdata_luabinding_TDCCMission_onBegin00
static int tolua_talkingdata_luabinding_TDCCMission_onBegin00(lua_State* tolua_S)
{
#ifndef TOLUA_RELEASE
 tolua_Error tolua_err;
 if (
     !tolua_isusertable(tolua_S,1,"TDCCMission",0,&tolua_err) ||
     !tolua_isstring(tolua_S,2,0,&tolua_err) ||
     !tolua_isnoobj(tolua_S,3,&tolua_err)
 )
  goto tolua_lerror;
 else
#endif
 {
  const char* missionId = ((const char*)  tolua_tostring(tolua_S,2,0));
  {
   TDCCMission::onBegin(missionId);
  }
 }
 return 0;
#ifndef TOLUA_RELEASE
 tolua_lerror:
 tolua_error(tolua_S,"#ferror in function 'onBegin'.",&tolua_err);
 return 0;
#endif
}
#endif //#ifndef TOLUA_DISABLE

/* method: onCompleted of class  TDCCMission */
#ifndef TOLUA_DISABLE_tolua_talkingdata_luabinding_TDCCMission_onCompleted00
static int tolua_talkingdata_luabinding_TDCCMission_onCompleted00(lua_State* tolua_S)
{
#ifndef TOLUA_RELEASE
 tolua_Error tolua_err;
 if (
     !tolua_isusertable(tolua_S,1,"TDCCMission",0,&tolua_err) ||
     !tolua_isstring(tolua_S,2,0,&tolua_err) ||
     !tolua_isnoobj(tolua_S,3,&tolua_err)
 )
  goto tolua_lerror;
 else
#endif
 {
  const char* missionId = ((const char*)  tolua_tostring(tolua_S,2,0));
  {
   TDCCMission::onCompleted(missionId);
  }
 }
 return 0;
#ifndef TOLUA_RELEASE
 tolua_lerror:
 tolua_error(tolua_S,"#ferror in function 'onCompleted'.",&tolua_err);
 return 0;
#endif
}
#endif //#ifndef TOLUA_DISABLE

/* method: onFailed of class  TDCCMission */
#ifndef TOLUA_DISABLE_tolua_talkingdata_luabinding_TDCCMission_onFailed00
static int tolua_talkingdata_luabinding_TDCCMission_onFailed00(lua_State* tolua_S)
{
#ifndef TOLUA_RELEASE
 tolua_Error tolua_err;
 if (
     !tolua_isusertable(tolua_S,1,"TDCCMission",0,&tolua_err) ||
     !tolua_isstring(tolua_S,2,0,&tolua_err) ||
     !tolua_isstring(tolua_S,3,0,&tolua_err) ||
     !tolua_isnoobj(tolua_S,4,&tolua_err)
 )
  goto tolua_lerror;
 else
#endif
 {
  const char* missionId = ((const char*)  tolua_tostring(tolua_S,2,0));
  const char* failedCause = ((const char*)  tolua_tostring(tolua_S,3,0));
  {
   TDCCMission::onFailed(missionId,failedCause);
  }
 }
 return 0;
#ifndef TOLUA_RELEASE
 tolua_lerror:
 tolua_error(tolua_S,"#ferror in function 'onFailed'.",&tolua_err);
 return 0;
#endif
}
#endif //#ifndef TOLUA_DISABLE

/* method: setAccount of class  TDCCAccount */
#ifndef TOLUA_DISABLE_tolua_talkingdata_luabinding_TDCCAccount_setAccount00
static int tolua_talkingdata_luabinding_TDCCAccount_setAccount00(lua_State* tolua_S)
{
#ifndef TOLUA_RELEASE
 tolua_Error tolua_err;
 if (
     !tolua_isusertable(tolua_S,1,"TDCCAccount",0,&tolua_err) ||
     !tolua_isstring(tolua_S,2,0,&tolua_err) ||
     !tolua_isnoobj(tolua_S,3,&tolua_err)
 )
  goto tolua_lerror;
 else
#endif
 {
  const char* accountId = ((const char*)  tolua_tostring(tolua_S,2,0));
  {
   TDCCAccount* tolua_ret = (TDCCAccount*)  TDCCAccount::setAccount(accountId);
    tolua_pushusertype(tolua_S,(void*)tolua_ret,"TDCCAccount");
  }
 }
 return 1;
#ifndef TOLUA_RELEASE
 tolua_lerror:
 tolua_error(tolua_S,"#ferror in function 'setAccount'.",&tolua_err);
 return 0;
#endif
}
#endif //#ifndef TOLUA_DISABLE

/* method: setAccountName of class  TDCCAccount */
#ifndef TOLUA_DISABLE_tolua_talkingdata_luabinding_TDCCAccount_setAccountName00
static int tolua_talkingdata_luabinding_TDCCAccount_setAccountName00(lua_State* tolua_S)
{
#ifndef TOLUA_RELEASE
 tolua_Error tolua_err;
 if (
     !tolua_isusertype(tolua_S,1,"TDCCAccount",0,&tolua_err) ||
     !tolua_isstring(tolua_S,2,0,&tolua_err) ||
     !tolua_isnoobj(tolua_S,3,&tolua_err)
 )
  goto tolua_lerror;
 else
#endif
 {
  TDCCAccount* self = (TDCCAccount*)  tolua_tousertype(tolua_S,1,0);
  const char* accountName = ((const char*)  tolua_tostring(tolua_S,2,0));
#ifndef TOLUA_RELEASE
  if (!self) tolua_error(tolua_S,"invalid 'self' in function 'setAccountName'", NULL);
#endif
  {
   self->setAccountName(accountName);
  }
 }
 return 0;
#ifndef TOLUA_RELEASE
 tolua_lerror:
 tolua_error(tolua_S,"#ferror in function 'setAccountName'.",&tolua_err);
 return 0;
#endif
}
#endif //#ifndef TOLUA_DISABLE

/* method: setAccountType of class  TDCCAccount */
#ifndef TOLUA_DISABLE_tolua_talkingdata_luabinding_TDCCAccount_setAccountType00
static int tolua_talkingdata_luabinding_TDCCAccount_setAccountType00(lua_State* tolua_S)
{
#ifndef TOLUA_RELEASE
 tolua_Error tolua_err;
 if (
     !tolua_isusertype(tolua_S,1,"TDCCAccount",0,&tolua_err) ||
     !tolua_isnumber(tolua_S,2,0,&tolua_err) ||
     !tolua_isnoobj(tolua_S,3,&tolua_err)
 )
  goto tolua_lerror;
 else
#endif
 {
  TDCCAccount* self = (TDCCAccount*)  tolua_tousertype(tolua_S,1,0);
  TDCCAccount::TDCCAccountType accountType = ((TDCCAccount::TDCCAccountType) (int)  tolua_tonumber(tolua_S,2,0));
#ifndef TOLUA_RELEASE
  if (!self) tolua_error(tolua_S,"invalid 'self' in function 'setAccountType'", NULL);
#endif
  {
   self->setAccountType(accountType);
  }
 }
 return 0;
#ifndef TOLUA_RELEASE
 tolua_lerror:
 tolua_error(tolua_S,"#ferror in function 'setAccountType'.",&tolua_err);
 return 0;
#endif
}
#endif //#ifndef TOLUA_DISABLE

/* method: setLevel of class  TDCCAccount */
#ifndef TOLUA_DISABLE_tolua_talkingdata_luabinding_TDCCAccount_setLevel00
static int tolua_talkingdata_luabinding_TDCCAccount_setLevel00(lua_State* tolua_S)
{
#ifndef TOLUA_RELEASE
 tolua_Error tolua_err;
 if (
     !tolua_isusertype(tolua_S,1,"TDCCAccount",0,&tolua_err) ||
     !tolua_isnumber(tolua_S,2,0,&tolua_err) ||
     !tolua_isnoobj(tolua_S,3,&tolua_err)
 )
  goto tolua_lerror;
 else
#endif
 {
  TDCCAccount* self = (TDCCAccount*)  tolua_tousertype(tolua_S,1,0);
  int level = ((int)  tolua_tonumber(tolua_S,2,0));
#ifndef TOLUA_RELEASE
  if (!self) tolua_error(tolua_S,"invalid 'self' in function 'setLevel'", NULL);
#endif
  {
   self->setLevel(level);
  }
 }
 return 0;
#ifndef TOLUA_RELEASE
 tolua_lerror:
 tolua_error(tolua_S,"#ferror in function 'setLevel'.",&tolua_err);
 return 0;
#endif
}
#endif //#ifndef TOLUA_DISABLE

/* method: setGender of class  TDCCAccount */
#ifndef TOLUA_DISABLE_tolua_talkingdata_luabinding_TDCCAccount_setGender00
static int tolua_talkingdata_luabinding_TDCCAccount_setGender00(lua_State* tolua_S)
{
#ifndef TOLUA_RELEASE
 tolua_Error tolua_err;
 if (
     !tolua_isusertype(tolua_S,1,"TDCCAccount",0,&tolua_err) ||
     !tolua_isnumber(tolua_S,2,0,&tolua_err) ||
     !tolua_isnoobj(tolua_S,3,&tolua_err)
 )
  goto tolua_lerror;
 else
#endif
 {
  TDCCAccount* self = (TDCCAccount*)  tolua_tousertype(tolua_S,1,0);
  TDCCAccount::TDCCGender gender = ((TDCCAccount::TDCCGender) (int)  tolua_tonumber(tolua_S,2,0));
#ifndef TOLUA_RELEASE
  if (!self) tolua_error(tolua_S,"invalid 'self' in function 'setGender'", NULL);
#endif
  {
   self->setGender(gender);
  }
 }
 return 0;
#ifndef TOLUA_RELEASE
 tolua_lerror:
 tolua_error(tolua_S,"#ferror in function 'setGender'.",&tolua_err);
 return 0;
#endif
}
#endif //#ifndef TOLUA_DISABLE

/* method: setAge of class  TDCCAccount */
#ifndef TOLUA_DISABLE_tolua_talkingdata_luabinding_TDCCAccount_setAge00
static int tolua_talkingdata_luabinding_TDCCAccount_setAge00(lua_State* tolua_S)
{
#ifndef TOLUA_RELEASE
 tolua_Error tolua_err;
 if (
     !tolua_isusertype(tolua_S,1,"TDCCAccount",0,&tolua_err) ||
     !tolua_isnumber(tolua_S,2,0,&tolua_err) ||
     !tolua_isnoobj(tolua_S,3,&tolua_err)
 )
  goto tolua_lerror;
 else
#endif
 {
  TDCCAccount* self = (TDCCAccount*)  tolua_tousertype(tolua_S,1,0);
  int age = ((int)  tolua_tonumber(tolua_S,2,0));
#ifndef TOLUA_RELEASE
  if (!self) tolua_error(tolua_S,"invalid 'self' in function 'setAge'", NULL);
#endif
  {
   self->setAge(age);
  }
 }
 return 0;
#ifndef TOLUA_RELEASE
 tolua_lerror:
 tolua_error(tolua_S,"#ferror in function 'setAge'.",&tolua_err);
 return 0;
#endif
}
#endif //#ifndef TOLUA_DISABLE

/* method: setGameServer of class  TDCCAccount */
#ifndef TOLUA_DISABLE_tolua_talkingdata_luabinding_TDCCAccount_setGameServer00
static int tolua_talkingdata_luabinding_TDCCAccount_setGameServer00(lua_State* tolua_S)
{
#ifndef TOLUA_RELEASE
 tolua_Error tolua_err;
 if (
     !tolua_isusertype(tolua_S,1,"TDCCAccount",0,&tolua_err) ||
     !tolua_isstring(tolua_S,2,0,&tolua_err) ||
     !tolua_isnoobj(tolua_S,3,&tolua_err)
 )
  goto tolua_lerror;
 else
#endif
 {
  TDCCAccount* self = (TDCCAccount*)  tolua_tousertype(tolua_S,1,0);
  const char* gameServer = ((const char*)  tolua_tostring(tolua_S,2,0));
#ifndef TOLUA_RELEASE
  if (!self) tolua_error(tolua_S,"invalid 'self' in function 'setGameServer'", NULL);
#endif
  {
   self->setGameServer(gameServer);
  }
 }
 return 0;
#ifndef TOLUA_RELEASE
 tolua_lerror:
 tolua_error(tolua_S,"#ferror in function 'setGameServer'.",&tolua_err);
 return 0;
#endif
}
#endif //#ifndef TOLUA_DISABLE

/* Open function */
TOLUA_API int tolua_talkingdata_luabinding_open (lua_State* tolua_S)
{
 tolua_open(tolua_S);
 tolua_reg_types(tolua_S);
 tolua_module(tolua_S,NULL,0);
 tolua_beginmodule(tolua_S,NULL);
  tolua_cclass(tolua_S,"TDCCVirtualCurrency","TDCCVirtualCurrency","",NULL);
  tolua_beginmodule(tolua_S,"TDCCVirtualCurrency");
   tolua_function(tolua_S,"onChargeRequest",tolua_talkingdata_luabinding_TDCCVirtualCurrency_onChargeRequest00);
   tolua_function(tolua_S,"onChargeSuccess",tolua_talkingdata_luabinding_TDCCVirtualCurrency_onChargeSuccess00);
   tolua_function(tolua_S,"onReward",tolua_talkingdata_luabinding_TDCCVirtualCurrency_onReward00);
  tolua_endmodule(tolua_S);
  tolua_cclass(tolua_S,"TDCCTalkingDataGA","TDCCTalkingDataGA","",NULL);
  tolua_beginmodule(tolua_S,"TDCCTalkingDataGA");
   tolua_function(tolua_S,"onStart",tolua_talkingdata_luabinding_TDCCTalkingDataGA_onStart00);
   tolua_function(tolua_S,"onEvent",tolua_talkingdata_luabinding_TDCCTalkingDataGA_onEvent00);
   tolua_function(tolua_S,"setLatitude",tolua_talkingdata_luabinding_TDCCTalkingDataGA_setLatitude00);
   tolua_function(tolua_S,"getDeviceId",tolua_talkingdata_luabinding_TDCCTalkingDataGA_getDeviceId00);
   tolua_function(tolua_S,"onKill",tolua_talkingdata_luabinding_TDCCTalkingDataGA_onKill00);
   tolua_function(tolua_S,"setVerboseLogEnabled",tolua_talkingdata_luabinding_TDCCTalkingDataGA_setVerboseLogEnabled00);
  tolua_endmodule(tolua_S);
  tolua_cclass(tolua_S,"TDCCItem","TDCCItem","",NULL);
  tolua_beginmodule(tolua_S,"TDCCItem");
   tolua_function(tolua_S,"onPurchase",tolua_talkingdata_luabinding_TDCCItem_onPurchase00);
   tolua_function(tolua_S,"onUse",tolua_talkingdata_luabinding_TDCCItem_onUse00);
  tolua_endmodule(tolua_S);
  tolua_cclass(tolua_S,"TDCCMission","TDCCMission","",NULL);
  tolua_beginmodule(tolua_S,"TDCCMission");
   tolua_function(tolua_S,"onBegin",tolua_talkingdata_luabinding_TDCCMission_onBegin00);
   tolua_function(tolua_S,"onCompleted",tolua_talkingdata_luabinding_TDCCMission_onCompleted00);
   tolua_function(tolua_S,"onFailed",tolua_talkingdata_luabinding_TDCCMission_onFailed00);
  tolua_endmodule(tolua_S);
  tolua_cclass(tolua_S,"TDCCAccount","TDCCAccount","",NULL);
  tolua_beginmodule(tolua_S,"TDCCAccount");
   tolua_constant(tolua_S,"kAccountAnonymous",TDCCAccount::kAccountAnonymous);
   tolua_constant(tolua_S,"kAccountRegistered",TDCCAccount::kAccountRegistered);
   tolua_constant(tolua_S,"kAccountSianWeibo",TDCCAccount::kAccountSianWeibo);
   tolua_constant(tolua_S,"kAccountQQ",TDCCAccount::kAccountQQ);
   tolua_constant(tolua_S,"kAccountTencentWeibo",TDCCAccount::kAccountTencentWeibo);
   tolua_constant(tolua_S,"kAccountND91",TDCCAccount::kAccountND91);
   tolua_constant(tolua_S,"kAccountType1",TDCCAccount::kAccountType1);
   tolua_constant(tolua_S,"kAccountType2",TDCCAccount::kAccountType2);
   tolua_constant(tolua_S,"kAccountType3",TDCCAccount::kAccountType3);
   tolua_constant(tolua_S,"kAccountType4",TDCCAccount::kAccountType4);
   tolua_constant(tolua_S,"kAccountType5",TDCCAccount::kAccountType5);
   tolua_constant(tolua_S,"kAccountType6",TDCCAccount::kAccountType6);
   tolua_constant(tolua_S,"kAccountType7",TDCCAccount::kAccountType7);
   tolua_constant(tolua_S,"kAccountType8",TDCCAccount::kAccountType8);
   tolua_constant(tolua_S,"kAccountType9",TDCCAccount::kAccountType9);
   tolua_constant(tolua_S,"kAccountType10",TDCCAccount::kAccountType10);
   tolua_constant(tolua_S,"kGenderUnknown",TDCCAccount::kGenderUnknown);
   tolua_constant(tolua_S,"kGenderMale",TDCCAccount::kGenderMale);
   tolua_constant(tolua_S,"kGenderFemale",TDCCAccount::kGenderFemale);
   tolua_function(tolua_S,"setAccount",tolua_talkingdata_luabinding_TDCCAccount_setAccount00);
   tolua_function(tolua_S,"setAccountName",tolua_talkingdata_luabinding_TDCCAccount_setAccountName00);
   tolua_function(tolua_S,"setAccountType",tolua_talkingdata_luabinding_TDCCAccount_setAccountType00);
   tolua_function(tolua_S,"setLevel",tolua_talkingdata_luabinding_TDCCAccount_setLevel00);
   tolua_function(tolua_S,"setGender",tolua_talkingdata_luabinding_TDCCAccount_setGender00);
   tolua_function(tolua_S,"setAge",tolua_talkingdata_luabinding_TDCCAccount_setAge00);
   tolua_function(tolua_S,"setGameServer",tolua_talkingdata_luabinding_TDCCAccount_setGameServer00);
  tolua_endmodule(tolua_S);
 tolua_endmodule(tolua_S);
 return 1;
}


#if defined(LUA_VERSION_NUM) && LUA_VERSION_NUM >= 501
 TOLUA_API int luaopen_talkingdata_luabinding (lua_State* tolua_S) {
 return tolua_talkingdata_luabinding_open(tolua_S);
};
#endif

