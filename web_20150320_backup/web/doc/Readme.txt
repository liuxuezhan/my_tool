[系统架构]
项目采用ZF2框架构建，包括4个模块：
User:		包括QQ/微信帐号信息查询、好友查询、游客模式鉴权等功能
Account:	包括QQ/微信余额信息查询、帐户扣减、取消扣减等功能
Idip:		包括IDIP接口功能
Gateway:	包括服务器列表的管理、用户关系的读取/写入

另外还有一个Application的模块，这个模块是系统自带的，同时它也作为上面4个模块的基类在使用，所以如果模块需要单独部署某模块的话，必须要带上它。


[接口访问&路由映射]
以下接口中{zone}值：iqq/aqq/iwx/awx
帐号类接口－－
QQ/WX帐号信息查询	/{zone}/user/profile
QQ/WX好友列表查询	/{zone}/user/friends
QQ/WX游客模式鉴权	/{zone}/user/guest-auth

SNS类接口－－
用户关系写入			/{zone}/sns/update
用户关系读取			/{zone}/sns/read

支付类接口－－
帐户余额查询			/{zone}/account/balance
帐户扣减			/{zone}/account/pay
帐户取消扣减			/{zone}/account/cancel-pay

IDIP接口－－
以下接口中{area}值：qq/wx
IDIP接口查询		/{area}/idip/send

网关类接口－－
该接口弃用，直接使用数据库维护。
(网页访问)
服务器列表显示		/server
服务器列表新增		/server/add
服务器列表编辑		/server/edit
服务器开服管理		/server/open
服务器关服管理		/server/close

[API说明]
请参见各模块对应Action注释，自解释。