<?php
namespace User\Controller;

//use Zend\Mvc\Controller\AbstractRestfulController;
use Zend\Mvc\Controller\AbstractActionController;
use Zend\View\Model\JsonModel;
use Zend\Db\Adapter\Adapter;

use User\Model\QQ;

class QqController extends AbstractActionController//AbstractRestfulController
{
   
    public function indexAction()
    {
        return new JsonModel(array(
            'data'  => 'This page is forbidden!',
        ));
    }
    
    /**
     * 取得QQ用户帐户信息接口
     * @param array  通过HTTP RAW POST方式提交数据，数据字段定义如下：
     *      platform        Integer   (required)腾讯平台定义。定义如下：１.微信，２.QQ，３.WT。４.QQ大厅。５.游客模式，此处只能为2
     *      os              Integer   (required)客户端操作系统定义。0: iOS, 1: Android
     *      open_id         String    (required)用户openID
     *      access_token    String    (required)用户访问接口的access_token
     * @return array 返回一个JSON数组，结构如下：
     *      ret             Integer   成功or失败。0失败，１成功
     *      msg             String    返回消息
     *      data            Mixed     返回数据，如果成功，返回格式如下：
     *          user_name       String  用户昵称
     *          user_id         String  用户的OpenID
     *          time            Integer 当前时间戳
     *          flag            String  该数据包的签名
     */
    public function profileAction()
    {
        $start_time = microtime(true);
        $logger = $this->getServiceLocator()->get('Zend\Log');
        $config = $this->getServiceLocator()->get('config');
        $user   = $this->getServiceLocator()->get('User\Model\QQ');
    
        $data = json_decode($this->request->getContent(), true);
        $logger->info('Data from client(post):');
        $logger->debug($data);
    
        if (($ret = $user->store($data)) === true) {
            $result = $user->getProfile($data);
            $end_time = microtime(true);
            
            //. $end_time-$start_time
            $expend_time = $end_time-$start_time;
            if ( $expend_time > 0.300 ) {
                $logger->debug("delay process: {$expend_time} sec ");
            }
            
            if ($result['ret'] === QQ::CX_CODE_SUCCESS) {
                $r_data = $result['data'];
                $logger->debug($r_data);
                if ($r_data['ret'] === QQ::TX_CODE_SUCCESS) {
                    $rdata = $user->signCxResponse(array(
                        'user_name' => $r_data['nickName'],
                        'user_id'   => $user->openid,
                    ));
                    $response = QQ::formatResponse(QQ::CX_CODE_SUCCESS, 'success', $rdata);
                } else {//MSDK Return result error
                    $response = QQ::formatResponse(QQ::CX_CODE_FAILED, 'MSDK return error!', $r_data);
                }
            } else {//MSDK Http response error
                $response = QQ::formatResponse($result);
            }
        } else {//Data validation failed
            $response = QQ::formatResponse(QQ::CX_CODE_FAILED, 'Data posted from client is invalid!', $ret);
        }
        
        //output
        //return new JsonModel($response);
        echo json_encode($response);
        exit;
    }
    
    /**
     * 取得QQ用户好友列表
     * @param array  通过HTTP RAW POST方式提交数据，数据字段定义如下：
     *      open_id         String    (required)用户openID
     *      time			string		(required)验签用的time
     *      access_token    String    (required)用户访问接口的access_token
     * @return array 返回一个JSON数组，结构如下：
     *      ret             Integer   成功or失败。0失败，１成功
     *      msg             String    返回消息
     *      lists            Mixed     返回数据，如果成功，返回格式如下：
     *      	openid		对应玩家id
     *          max_fc		最大战力
     *          level		等级
     *          integral		积分
     *          integral_type		积分类型
     *          is_send			是否送过此人
     *          is_accpet		是否被此人赠送体力
     *          strength_id		如果被赠送体力，则带上记录id
     */
    public function getFriendsAction()
    {
    	//ini_set('display_errors',0);
    	$logger = $this->getServiceLocator()->get('Zend\Log');
    	$config = $this->getServiceLocator()->get('config');
    	$user   = $this->getServiceLocator()->get('User\Model\QQ');
    	
    	$data = json_decode($this->request->getContent(), true);
    	$logger->info('Data from client(post):');
    	$logger->debug($data);
    	self::putLog("getFriendsAction —------———Data from client:");
    	self::putLog($data);
//     	$data['open_id'] = "9DC47F6F96B7A77A816CC18F8BEB9D85";
//     	$data['time'] = "1423139052";
//     	$data['access_token'] = "BC660A9BACFB9BF6FE33FDCD7C36D2E6";
//     	$data['data'] = array(
//     				"5B039C77EAB7ECE4E8FED6D5E5D1D9D7",
//     				"9DC47F6F96B7A77A816CC18F8BEB9D85"
//     			);
    	
    	$return = array();
    	
    	if (isset($data['open_id']) && is_array($data['data'])) {	
    		if(!$user->checkToken($data['open_id'], $data['time'], $data['access_token']))
    		{
    			self::putLog("token invalid");
    			$return['ret'] = 0;
    			$return['msg'] = "token invalid";
    			echo json_encode($return);
    			exit;
    		}else{
    			/******************获取好友对应等级、战力、积分、积分类型(新加)***********************/
    			$today = strtotime(date("Y-m-d 00:00:00"));
    			$link = $this -> connectDb();
    			foreach($data['data'] as $k => $v)
    			{
    				$return['lists'][$k]['openid'] = $v;
    				
    				$result = $link->query("select max_fc,level,integral from AQQ_FRIENDS_TBL where openid='{$v}' limit 0,1");
    				if($result){
    					$result = mysqli_fetch_assoc($result);
    				}else{
    					$result['max_fc'] = 0;
    					$result['level'] = 0;
    					$result['integral'] = '0-0-0-0-0';
    				}
    				$return['lists'][$k]['max_fc'] = $result['max_fc'] ? $result['max_fc'] : 0;
    				$return['lists'][$k]['level'] = $result['level'] ? $result['level'] : 0;
    				$return['lists'][$k]['integral'] = $result['integral'] ? $result['integral'] : '0-0-0-0-0';
    				//是否对该好友赠送过体力
    				$result2 = $link->query("select count(*) as num from AQQ_STRENGTH_TBL where send_openid='{$data['open_id']}' and accpet_openid='{$v}' and send_time>{$today}");
    				//self::putLog("select count(*) as num from AQQ_STRENGTH_TBL where send_openid='{$data['open_id']}' and accpet_openid='{$v['openid']}' and send_time>{$today}");
    				$result2 = mysqli_fetch_assoc($result2);
    				if($result2['num'] > 0 && $result2)
    				{
    					$return['lists'][$k]['is_send'] = 1;
    				}else{
    					$return['lists'][$k]['is_send'] = 0;
    				}
    				//是否被该好友赠送体力
    				$rs1 = array();
    				$sql = "select id,num from AQQ_STRENGTH_TBL where send_openid='{$v}' and accpet_openid='{$data['open_id']}' and is_get=0 limit 0,1";
    				$result1 = $link->query($sql);
    				$rs1 = mysqli_fetch_assoc($result1);
    				if($rs1['id'] && $rs1['num'])
    				{
    					$return['lists'][$k]['is_accpet'] = 1;
    					$return['lists'][$k]['strength_id'] = $rs1['id'];
    				}else{
    					$return['lists'][$k]['is_accpet'] = 0;
    					$return['lists'][$k]['strength_id'] = 0;
    				}
    				//被挑战时间
    				$sql = "select time from AQQ_FIGHTING_TBL where accpet_openid='{$v}' and start_openid='{$data['open_id']}' order by time desc limit 0,1";
    				$result2 = $link->query($sql);
    				$result2 = @mysqli_fetch_assoc($result2);
    				if($result2 && $result2['time'])
    				{
    					$return['lists'][$k]['challenge_time'] = $result2['time']; 
    				}else{
    					$return['lists'][$k]['challenge_time'] = 0;
    				}
    			}
    			mysqli_close($link);
    			/***********************************************/
    			$return['msg'] = 'success';
    			$return['ret'] = 1;
    		}
    	}else{
    		$return['ret'] = 0;
    		$return['msg'] = "no openid or no data";
    	}
    	self::putLog("getFriendsAction ——------------——Data give client:");
    	self::putLog($return);
    	
    	echo json_encode($return);
    	exit;
    }
    /**
     * 取得QQ用户好友列表
     * @param array  通过HTTP RAW POST方式提交数据，数据字段定义如下：
     *      platform        Integer   (required)腾讯平台定义。定义如下：１.微信，２.QQ，３.WT。４.QQ大厅。５.游客模式，此处只能为2
     *      os              Integer   (required)客户端操作系统定义。0: iOS, 1: Android
     *      open_id         String    (required)用户openID
     *      access_token    String    (required)用户访问接口的access_token
     * @return array 返回一个JSON数组，结构如下：
     *      ret             Integer   成功or失败。0失败，１成功
     *      msg             String    返回消息
     *      data            Mixed     返回数据，如果成功，返回格式如下：
     *          lists           List    好友信息列表
     *          time            Integer 当前时间戳
     *          flag            String  该数据包的签名
     */
    public function friendsAction()
    {
        $logger = $this->getServiceLocator()->get('Zend\Log');
        $config = $this->getServiceLocator()->get('config');
        $user   = $this->getServiceLocator()->get('User\Model\QQ');
        
        $data = json_decode($this->request->getContent(), true);
        $logger->info('Data from client(post):');
        $logger->debug($data);
        self::putLog("friendsAction——-----------——Data from client:");
        self::putLog($data);
// 		$data['open_id'] = "B26687C0A3E608AFFE368F28B4056502";
// 		$data['time'] = "1423139052";
// 		$data['access_token'] = "C32475EDF60206C0947693E44730566E";
// 		$data['platform'] = 2;
// 		$data['os'] = 1;
        
        if (($ret = $user->store($data)) === true) {
            $result = $user->getFriends($data);
            if ($result['ret'] === QQ::CX_CODE_SUCCESS) {
                $r_data = $result['data'];
                $logger->debug($r_data);
                if ($r_data['ret'] === QQ::TX_CODE_SUCCESS) {
                    $rdata = $user->signCxResponse(array(
                        'lists'     => $r_data['lists'],
                    ));
                    $response = QQ::formatResponse(QQ::CX_CODE_SUCCESS, 'success', $rdata);
                } else {//MSDK Return result error
                    $response = QQ::formatResponse(QQ::CX_CODE_FAILED, 'MSDK return error!', $r_data);
                }
            } else {//MSDK Http response error
                $response = QQ::formatResponse($result);
            }
        } else {//Data validation failed
            $response = QQ::formatResponse(QQ::CX_CODE_FAILED, 'Data posted from client is invalid!', $ret);
        }
        self::putLog("friendsAction---------------------Data give client:");
        self::putLog($response);
        //output
        //return new JsonModel($response);
        echo json_encode($response);
        exit;
    }
    
    /**
     * 游客模式签权(QQ)
     * @param array  通过HTTP RAW POST方式提交数据，数据字段定义如下：
     *      platform        Integer   (required)腾讯平台定义。定义如下：１.微信，２.QQ，３.WT。４.QQ大厅。５.游客模式，此处只能为5
     *      os              Integer   (required)客户端操作系统定义。0: iOS, 1: Android
     *      open_id         String    (required)用户openID
     *      access_token    String    (required)用户访问接口的access_token
     * @return array 返回一个JSON数组，结构如下：
     *      ret             Integer   成功or失败。0失败，１成功
     *      msg             String    返回消息
     *      data            Mixed     返回数据，如果成功，返回格式如下：
     *          user_name       String  显示为Guest
     *          user_id         String  用户OpenID
     *          time            Integer 当前时间戳
     *          flag            String  该数据包的签名
     */
    public function guestAuthAction()
    {
        $logger = $this->getServiceLocator()->get('Zend\Log');
        $config = $this->getServiceLocator()->get('config');
        $user   = $this->getServiceLocator()->get('User\Model\QQ');
        
        $data = json_decode($this->request->getContent(), true);
        $logger->info('Data from client(post):');
        $logger->debug($data);
        
        if (($ret = $user->store($data)) === true) {
            $result = $user->guestCheckToken($data);
            if ($result['ret'] === QQ::CX_CODE_SUCCESS) {
                $r_data = $result['data'];
                if ($r_data['ret'] === QQ::TX_CODE_SUCCESS) {
                    $rdata = $user->signCxResponse(array(
                        'user_name' => 'Guest',
                        'user_id'   => $user->openid,
                    ));
                    $response = QQ::formatResponse(QQ::CX_CODE_SUCCESS, 'success', $rdata);
                } else {//MSDK Return result error
                    $response = QQ::formatResponse(QQ::CX_CODE_FAILED, 'MSDK return error!', $r_data);
                }
            } else {//MSDK Http response error
                $response = QQ::formatResponse($result);
            }
        } else {//Data validation failed
            $response = QQ::formatResponse(QQ::CX_CODE_FAILED, 'Data posted from client is invalid!', $ret);
        }
        
        //output
        //return new JsonModel($response);
        echo json_encode($response);
        exit;
    }
    /**
     * 更新阵容、战斗力(QQ)
     * @param array  通过HTTP RAW POST方式提交数据，数据字段定义如下：
     *      openid          String    (required)用户openID
     *      time            String    (required)签名时间
     *      access_token    String    (required)用户访问接口的access_token
     *      max_fc			integer	  (required)最高战斗力
     *      team			mixed	  (required)阵容
     *      level		    integer	  (required)最高等级
     * @return array 返回一个JSON数组，结构如下：
     *      ret            Integer   成功or失败。0失败，１成功
     *      msg             String    返回消息
     */
    public function updateTeamAction()
    {
    	$logger = $this->getServiceLocator()->get('Zend\Log');
    	$config = $this->getServiceLocator()->get('config');
    	$user   = $this->getServiceLocator()->get('User\Model\QQ');
    	
    	$data = json_decode($this->request->getContent(), true);
    	$logger->info('Data from client(post):');
    	$logger->debug($data);
    	self::putLog("updateTeamAction——-------——Data from client:");
    	self::putLog($data);  
//     	$data['open_id'] = "664FF60DB9EA606B1E241355A2C943B5";
//     	$data['time'] = "1423120941";
//     	$data['access_token'] = "F59B9958E2933C0177008191A05F2628";
//     	$data['max_fc'] = 123123;
//     	$data['team'] = array('leader'=>-1,'arr'=>array(array(123,123),array(3,4)));
//     	$data['level'] = 3;	
    	
    	$return = array();
    	$link = $this -> connectDb();
    	
    	if ($data['open_id']) {
    		
    		if(!$user->checkToken($data['open_id'], $data['time'], $data['access_token']))
    		{
    			self::putLog("token invalid");
    			$return['ret'] = 0;
    			$return['msg'] = "token invalid";
    			echo json_encode($return);
    			exit;
    		}else{
    		
	    		$result = $link->query("select max_fc,level,openid from AQQ_FRIENDS_TBL where openid='{$data['open_id']}'");
	    		$result = mysqli_fetch_assoc($result);	
	    		//已有玩家记录则更新，否则插入新记录
	    		$team = $data['team'];
// 	    		self::putLog("----------------------------------------------team---------------------------------------");
// 	    		self::putLog($team);
	    		if($result['openid'])
	    		{   
	    			if($team != -1)
	    			{			
	    				if($data['max_fc'] > $result['max_fc'])
	    				{
	    					$max_fc = ",max_fc='{$data['max_fc']}'";
	    				}else{
	    					$max_fc = "";
	    				}
	    				if($data['level'] > $result['level'])
	    				{
	    					$level = ",level='{$data['level']}' ";
	    				}else{
	    					$level = "";
	    				}
		    			$sql = "update AQQ_FRIENDS_TBL set team='{$team}'{$level}{$max_fc} where openid='{$data['open_id']}'";
// 		    			self::putLog($sql);
		    			$ret = $link->query($sql);
		    			if(!$ret)
		    			{
		    				$return['msg'] = "cannot update AQQ_FRIENDS_TBL";
		    			}else{
		    				$return['ret'] = 1;
		    			}
	    			}else{
	    				$return['ret'] = 2;
	    				$return['msg'] = 'no team data';
	    			}
		    		
	    		}elseif($result['num'] == 0){
	    			$sql = "insert AQQ_FRIENDS_TBL(openid,max_fc,team,level) values('{$data['open_id']}','{$data['max_fc']}','{$team}','{$data['level']}')";
	    			//self::putLog($sql);
	    			$return['ret'] = $link->query($sql);
	    			if(!$return['ret'])
	    			{
	    				$return['ret'] = 0;
	    				$return['msg'] = "cannot insert AQQ_FRIENDS_TBL:";
	    			}else{
	    				$return['ret'] = 1;
	    			}
	    		}else{
	    			$return['ret'] = 0;
	    			$return['msg'] = "the num is not correct";
	    		}
    		}
    	}else{
    		$return['ret'] = 0;
    		$return['msg'] = "invalid openid";
    	}
    	
    	self::putLog("updateTeamAction--------data give client:");
    	self::putLog($return);
    	
    	mysqli_close($link);
    	echo json_encode($return);
    	exit;
    }
    /**
     * 查询阵容、战斗力(QQ)
     * @param array  通过HTTP RAW POST方式提交数据，数据字段定义如下：
     *      open_id          String    (required)用户openID
     *      time            String    (required)签名时间
     *      access_token    String    (required)用户访问接口的access_token
     * @return array 返回一个JSON数组，结构如下：
     *      ret            Integer   成功or失败。0失败，１成功
     *      msg             String    返回消息
     */
    public function teamAction()
    {
    	$logger = $this->getServiceLocator()->get('Zend\Log');
    	$config = $this->getServiceLocator()->get('config');
    	$user   = $this->getServiceLocator()->get('User\Model\QQ');
    	
    	$data = json_decode($this->request->getContent(), true);
    	$logger->info('Data from client(post):');
    	$logger->debug($data);
// 		$data['accpet_openid'] = '664FF60DB9EA606B1E241355A2C943B5';
//     	$data['open_id'] = '664FF60DB9EA606B1E241355A2C943B5';
//     	$data['time'] = '1423051029';
//     	$data['access_token'] = 'AC82AF926EADFFB150F349B8B4CDBDF6';
    	self::putLog("teamAction——----------——Data from client:");
    	self::putLog($data);
    	
    	$return = array();
    	$link = $this -> connectDb();
    	
    	if(isset($data['open_id']))
    	{
    		
    		if(!$user->checkToken($data['open_id'], $data['time'], $data['access_token']))
    		{
    			self::putLog("token invalid");
    			$return['ret'] = 0;
    			$return['msg'] = "token invalid";
    			echo json_encode($return);
    			exit;
    		}else{
    		
	    		$sql = "select max_fc,team,openid,level from AQQ_FRIENDS_TBL where openid='{$data['accpet_openid']}'";
	    		$result = $link->query($sql);
	    		if($result)
	    		{
	    			$return = mysqli_fetch_assoc($result);
// 	    			self::putLog("---------------------------------------------------give:-----------------------------------------");
//     				self::putLog($return);
	    			$return['ret'] = 1;
	    		}else{
	    			$return['ret'] = 0;
	    			$return['msg'] = "can not get information from AQQ_FRIENDS_TBL";
	    		}
    		}
    	}else{
    		$return['ret'] = 0;
    		$return['msg'] = "openid is null";
    	}
    	self::putLog("teamAction----------------------Data give client:");
    	self::putLog($return);
    	
    	mysqli_close($link);
    	echo json_encode($return);
    	exit;
    }
    /**
     * 赠送体力(QQ)
     * @param array  通过HTTP RAW POST方式提交数据，数据字段定义如下：
     *      send_openid     String    (required)赠送体力的玩家标识
     *      time            String    (required)签名时间
     *      access_token    String    (required)用户访问接口的access_token
     *      accpet_openid   String    (required)接受赠送体力的玩家标识
     *      num             integer   (required)赠送体力的数量
     *      platform
     *      os
     *      account
     *      zoneid
     * @return array 返回一个JSON数组，结构如下：
     *      ret            Integer   成功or失败。0失败，１成功
     *      msg            String    返回消息
     */
    public function sendStrengthAction()
    {
    	$logger = $this->getServiceLocator()->get('Zend\Log');
    	$config = $this->getServiceLocator()->get('config');
    	$user   = $this->getServiceLocator()->get('User\Model\QQ');
    	
    	$data = json_decode($this->request->getContent(), 1);
    	$logger->info('sendStrengthAction------------Data from client(post):');
    	$logger->debug($data);
//     	$data['send_openid'] = '664FF60DB9EA606B1E241355A2C943B5';
//     	$data['accpet_openid'] = '664FF60DB9EA606B1E241355A2C943B5';
//     	$data['time'] = '1423051029';
//     	$data['access_token'] = 'AC82AF926EADFFB150F349B8B4CDBDF6';
//     	$num = 5;
    	self::putLog("sendStrengthAction————Data from client:");
    	self::putLog($data);
    	
    	$return = array();
    	$link = $this -> connectDb();
    	
    	if(isset($data['send_openid']) && isset($data['accpet_openid']))
    	{
    		if(!$user->checkToken($data['send_openid'], $data['time'], $data['access_token']))
    		{
    			self::putLog("token invalid");
    			$return['ret'] = 0;
    			$return['msg'] = "token invalid";
    			echo json_encode($return);
    			exit;
    		}
    		$return['ret'] = 1;
    		$return['msg'] = "test";
    		$return['msg'] = self::strength($data, $data['account'], 3);
    		//当天每人赠送一次
    		$time = strtotime(date('Y-m-d')."00:00:00");//今日凌晨
    		$result = $link->query("select count(*) as num from AQQ_STRENGTH_TBL where send_openid='{$data['send_openid']}' and accpet_openid='{$data['accpet_openid']}' and send_time>{$time}");
    		$rs = mysqli_fetch_assoc($result);
    		
    		if($rs['num'] == 0)
    		{
    			$result = $link->query("select count(*) as num from AQQ_STRENGTH_TBL where accpet_openid='{$data['accpet_openid']}' and send_time>{$time}");
    			$rs = mysqli_fetch_assoc($result);
    			//每人每天接受10次赠送
    			if($rs['num'] < 10)
    			{
    				$now = time();
    				$sql = "insert AQQ_STRENGTH_TBL(send_openid,accpet_openid,num,send_time) values('{$data['send_openid']}','{$data['accpet_openid']}','2','{$now}')";
    				$return['ret'] = $link->query($sql);
    				if(!$return['ret'])
    				{
    					$return['ret'] = 0;
    					$return['msg'] = "insert error:".mysqli_error($link);
    				}else{
    					//自己获取3点
    					$back = self::strength($data, $data['account'], 3);
    					if($back['result'] == 1)
    					{
    						$return['ret'] = 1;
    						$return['msg'] = 'success';
    					}else{
    						$return['ret'] = 0;
    						$return['back'] = $back;
    					}
    				}
    			}else{
    				$return['ret'] = 3;
    				$return['msg'] = "more than 10";
    			}
    		}else{
    			$return['ret'] = 2;
    			$return['msg'] = "one people one time";
    		}
    		
    	}else{
    		$return['ret'] = 0;
    		$return['msg'] = 'no send_openid or no accpet_openid';
    	}
    	self::putLog("sendStrengthAction-----------------Data give client:");
    	self::putLog($return);
    	
    	mysqli_close($link);
    	echo json_encode($return);
    	exit;
    }
    /**
     * 获取体力(QQ)
     * @param array  通过HTTP RAW POST方式提交数据，数据字段定义如下：
     *      platform        Integer   (required)腾讯平台定义。定义如下：１.微信，２.QQ，３.WT。４.QQ大厅。５.游客模式
     *      os              Integer   (required)客户端操作系统定义。0: iOS, 1: Android
     *      zone_id          Integer   (required)腾讯zoneid定义
     *      num     		integer    (required)赠送体力
     *      open_id         String    (required)用户openID
     *      time            String    (required)签名时间
     *      access_token    String    (required)用户访问接口的access_token
     * @return array 返回一个JSON数组，结构如下：
     *      ret            Integer   成功or失败。0失败，１成功
     *      msg            String    返回消息
     */
    public function acceptStrengthAction()
    {
    	$logger = $this->getServiceLocator()->get('Zend\Log');
    	$config = $this->getServiceLocator()->get('config');
    	$user   = $this->getServiceLocator()->get('User\Model\QQ');
    	
    	$data = json_decode($this->request->getContent(), 1);
    	$logger->info('Data from client(post):');
    	$logger->debug($data);
    	self::putLog("acceptStrengthAction————获取体力--------------------Data from client:");
    	self::putLog($data);
// 		$num = 9;
// 		$data['account'] = "";
//     	$data['open_id'] = '664FF60DB9EA606B1E241355A2C943B5';
//     	$data['time'] = '1423051029';
//     	$data['access_token'] = 'AC82AF926EADFFB150F349B8B4CDBDF6';
// 		$data['platform'] = 2;
// 		$data['os'] = 1;
// 		$data['zoneid'] = 3;
    	
    	$return = array();
    	$link = $this -> connectDb();
    	
    	if(isset($data['open_id']) && isset($data['account']))
    	{
    		if(!$user->checkToken($data['open_id'], $data['time'], $data['access_token']))
    		{
    			self::putLog("token invalid");
    			$return['ret'] = 0;
    			$return['msg'] = "token invalid";
    			echo json_encode($return);
    			exit;
    		}
    		$sql = "select num,is_get from AQQ_STRENGTH_TBL where id='{$data['strength_id']}'";
    		$result = $link->query($sql);
    		
    		if($result)
    		{
    			$result = mysqli_fetch_assoc($result);
    			if($result['is_get'] == 0)
    			{
	    			
	    			self::putLog("赠送体力服务器返回数据");
	    			self::putLog($return);
	    			$rs = self::strength($data, $data['account'], 2);
	    			if($rs['result'] == 1 || $rs['result'] == 10003){
	    				$return['ret'] = 1;
	    				$return['index'] = $data['index'];
	    			}
	    			$link->query("update AQQ_STRENGTH_TBL set is_get=1 where id='{$data['strength_id']}' ");
    			}else{
    				$return['ret'] = 2;
    				$return['msg'] = 'already get';
    			}
    		}else{
    			$return['ret'] = 0;
    			$return['msg'] = "no data in AQQ_STRENGTH_TBL";
    		}
    	}else{
    		$return['ret'] = 0;
    		$return['msg'] = "no open_id or no account";
    	}
        
    	self::putLog("acceptStrengthAction————获取体力--------------------Data give client:");
    	self::putLog($return);
    	
        echo json_encode($return);
        exit;
    }
    
    public function strength($data, $account, $num){
    	$logger = $this->getServiceLocator()->get('Zend\Log');
    	$config = $this->getServiceLocator()->get('config');
    	$user   = $this->getServiceLocator()->get('User\Model\QQ');
    	
    	$sig = QQ::makeCxSignature1(array(
    			$account,
    			$num,
    			QQ::CX_SIG_FRIENDS_KEY,
    	), $logger);
//     	$rdata = $user->signCxResponse(array(
//     			'account'       => $account,
//     			'num'           => $num,
//     			'flag'          => $sig,
//     	));
		$rdata = array();
		$rdata['flag'] = $sig;
		$rdata['account'] = $account;
		$rdata['num'] = $num;
    	$response = QQ::formatResponse(QQ::CX_CODE_SUCCESS, 'success', $rdata);
    	
    	self::putLog("response:");
    	self::putLog($response);
    	//send GM command to GS
    	//根据area_id/plat_id/partition查找数据库连接
    	$adapter_name = "gateway";
    	$adapter = $this->getServiceLocator()->get($adapter_name);
    	
    	$sql = "SELECT ip, port, db_host, db_port, db_name, db_user, db_pass, status FROM servers WHERE area_id = {$data['platform']} AND plat_id = {$data['os']} AND partition = {$data['zone_id']}";
//     	$logger->info("execute sql: $sql");
    	self::putLog("execute sql:");
    	self::putLog($sql);
//     	$result = $adapter->query($sql);
//     	$logger->debug('find db info on gateway');
//     	self::putLog("select from servers:");
//     	self::putLog(print_r($result));
		$link = mysqli_connect('192.168.0.6','root','root','gateway');
		$result = $link->query($sql);
		$result = mysqli_fetch_assoc($result);
		self::putLog("select from servers:");
		self::putLog($result);
    	
//     	if (!empty($result)) {
//     		$gs_config = array();
//     		foreach ($result as $row) {
//     			$gs_config['status'] = $row['status'];
//     			$gs_config['host'] = $row['db_host'];
//     			$gs_config['port'] = $row['db_port'];
//     			$gs_config['name'] = $row['db_name'];
//     			$gs_config['user'] = $row['db_user'];
//     			$gs_config['pass'] = $row['db_pass'];
    	
//     			$gs_config['gs_ip'] = $row['ip'];
//     			$gs_config['gs_port'] = $row['port'];
//     		}
    	
//     		$gm_result = QQ::sendGMCmd($response, $gs_config['gs_ip'], $gs_config['gs_port'], false);
//     		$logger->debug($gm_result);
    	
//     		return $gm_result;
//     	}else{
    		$gm_result = QQ::sendGMCmd1($response, '192.168.0.3', '9051', false);
    		$logger->debug($gm_result);
    		
    		return $gm_result;
//     	}
    	
    	//return 0;
    }
    /**
     * 记录玩家挑战结果(QQ)
     * @param array  通过HTTP RAW POST方式提交数据，数据字段定义如下：
     *      start_openid：开启挑战的玩家标识
     *      time            String    (required)签名时间
     *      access_token    String    (required)用户访问接口的access_token
     *      accpet_openid:接受挑战的玩家标识
     *      is_vitory：是否成功 1成功  0失败
     *      video：挑战录像（用于玩家回放）
     *      time：挑战时间
     * @return array 返回一个JSON数组，结构如下：
     *      ret            Integer   成功or失败。0失败，１成功
     *      msg            String    返回消息
     */
    public function challengeAction()
    {
    	$logger = $this->getServiceLocator()->get('Zend\Log');
    	$config = $this->getServiceLocator()->get('config');
    	$user   = $this->getServiceLocator()->get('User\Model\QQ');
    	
    	$data = json_decode($this->request->getContent(), 1);
    	$logger->info('Data from client(post):');
    	$logger->debug($data);
    	self::putLog("challengeAction————Data from client:");
    	self::putLog($data);
//     	$data['start_openid'] = '664FF60DB9EA606B1E241355A2C943B5';
//     	$data['accpet_openid'] = '664FF60DB9EA606B1E241355A2C943B5';
//     	$data['time'] = '1423051029';
//     	$data['access_token'] = 'AC82AF926EADFFB150F349B8B4CDBDF6';
//     	$data['challenge_time'] = time();
//     	$data['is_victory'] = 1;
//     	$data['video'] = 'sdfsdfsf';
    	
    	$return = array();
    	$link = $this -> connectDb();
    	
    	if(isset($data['start_openid']) && isset($data['accpet_openid']))
    	{	
    		if(!$user->checkToken($data['start_openid'], $data['time'], $data['access_token']))
    		{
    			self::putLog("token invalid");
    			$return['ret'] = 0;
    			$return['msg'] = "token invalid";
    			echo json_encode($return);
    			exit;
    		}else{
	    		$sql = "insert AQQ_FIGHTING_TBL(start_openid,accpet_openid,is_victory,video,time) values('{$data['start_openid']}','{$data['accpet_openid']}','{$data['is_victory']}','{$data['video']}','{$data['challenge_time']}')";
	    		$return['ret'] = $link->query($sql);
	    		if(!$return['ret'])
	    		{
	    			$return['ret'] = 0;
	    			$return['msg'] = 'insert error';
	    		}else{
	    			$return['ret'] = 1;
	    		}
    		}
    	}else{
    		$return['ret'] = 0;
    		$return['msg'] = "no start_openid or no accpet_openid";
    	}
    	self::putLog("challengeAction--------------Data give client:");
    	self::putLog($return);
    	
    	mysqli_close($link);
    	echo json_encode($return);
    	exit;
    }
    /**
     * 玩家被挑战历史信息(QQ)
     * @param array  通过HTTP RAW POST方式提交数据，数据字段定义如下：
     *      open_id          String    (required)用户openID
     *      time            String    (required)签名时间
     *      access_token    String    (required)用户访问接口的access_token
     * @return array 返回一个JSON数组，结构如下：
     *      ret            Integer   成功or失败。0失败，１成功
     *      msg            String    返回消息
     */
    public function historyChallengeAction()
    {
    	$logger = $this->getServiceLocator()->get('Zend\Log');
    	$config = $this->getServiceLocator()->get('config');
    	$user   = $this->getServiceLocator()->get('User\Model\QQ');
    	
    	$data = json_decode($this->request->getContent(), 1);
    	$logger->info('Data from client(post):');
    	$logger->debug($data);
    	self::putLog("historyChallengeAction————Data from client:");
    	self::putLog($data);
//     	$data['open_id'] = '664FF60DB9EA606B1E241355A2C943B5';
//     	$data['time'] = '1423051029';
//     	$data['access_token'] = 'AC82AF926EADFFB150F349B8B4CDBDF6';
    	
    	$return = array();
    	$link = $this -> connectDb();
    	
    	if(isset($data['open_id']))
    	{
    		if(!$user->checkToken($data['open_id'], $data['time'], $data['access_token']))
    		{
    			self::putLog("token invalid");
    			$return['ret'] = 0;
    			$return['msg'] = "token invalid";
    			echo json_encode($return);
    			exit;
    		}else{
	    		$sql = "select start_openid,accpet_openid,is_victory,time from AQQ_FIGHTING_TBL where accpet_openid='{$data['open_id']}' order by time asc";
	    		$result = $link->query($sql);
	    		if($result)
	    		{
	    			$return['data'] = array();
	    			while($row = mysqli_fetch_assoc($result))
	    			{
	    				$return['data'][] = $row;
	    			}
	    			$result1 = $link->query("select max_fc,level,integral from AQQ_FRIENDS_TBL where openid='{$data['open_id']}'");
	    			if($result1){
	    				$result1 = mysqli_fetch_assoc($result1);
	    				$return['max_fc'] = $result1['max_fc'];
	    				$return['level'] = $result1['level'];
	    				$return['integral'] = $result1['integral'];
	    			}else{
	    				$return['max_fc'] = 0;
	    				$return['level'] = 0;
	    				$return['integral'] = '';
	    			}
	    			$return['ret'] = 1;
	    		}else{
	    			$return['ret'] = 0;
	    			$return['msg'] = "cannot get data from AQQ_FIGHTING_TBL";
	    		}
    		}
    	}else{
    		$return['ret'] = 0;
    		$return['msg'] = "no open_id";
    	}
    	self::putLog("historyChallengeActjon---------------Data give client:");
    	self::putLog($return);
    	
    	mysqli_close($link);
    	echo json_encode($return);
    	exit;
    }
    /**
     * 玩家单次被挑战信息(QQ)
     * @param array  通过HTTP RAW POST方式提交数据，数据字段定义如下：
     *      id：挑战记录id
     *      open_id          String    (required)用户openID
     *      time            String    (required)签名时间
     *      access_token    String    (required)用户访问接口的access_token
     * @return array 返回一个JSON数组，结构如下：
     *      ret            Integer   成功or失败。0失败，１成功
     *      data		   mixed     查询成功返回数据
     *      msg            String    返回消息
     */
    public function historyChallengeOneAction()
    {
    	$logger = $this->getServiceLocator()->get('Zend\Log');
    	$config = $this->getServiceLocator()->get('config');
    	$user   = $this->getServiceLocator()->get('User\Model\QQ');
    	
    	$data = json_decode($this->request->getContent(), 1);
    	$logger->info('Data from client(post):');
    	$logger->debug($data);
    	self::putLog("historyChallengeOneAction————Data from client:");
    	self::putLog($data);
//     	$data['open_id'] = '664FF60DB9EA606B1E241355A2C943B5';
//     	$data['time'] = '1423051029';
//     	$data['access_token'] = 'AC82AF926EADFFB150F349B8B4CDBDF6';
//     	$data['id'] = 3;
    	
    	$return = array();
    	$link = $this -> connectDb();
 
    	if(isset($data['id']))
    	{
    		if(!$user->checkToken($data['open_id'], $data['time'], $data['access_token']))
    		{
    			self::putLog("token invalid");
    			$return['ret'] = 0;
    			$return['msg'] = "token invalid";
    			echo json_encode($return);
    			exit;
    		}else{
	    		$sql = "select start_openid,accpet_openid,video,is_victory,time from AQQ_FIGHTING_TBL where id={$data['id']}";
	    		$result = $link->query($sql);
	    		if($result)
	    		{
	    			$return['data'] = mysqli_fetch_assoc($result);
	    			$return['ret'] = 1;
	    		}else{
	    			$return['ret'] = 0;
	    			$return['msg'] = "cannot get data from AQQ_FIGHTING_TBL";
	    		}
    		}
    	}else{
    		$return['ret'] = 0;
    		$return['msg'] = "no id";
    	}
    	self::putLog("historyChallengeOneAction-----------------Data give client:");
    	self::putLog($return);
    	
    	mysqli_close($link);
    	echo json_encode($return);
    	exit;
    }
    /**
     * 上传积分信息(QQ)
     * @param array  通过HTTP RAW POST方式提交数据，数据字段定义如下：
     *      open_id          String    (required)用户openID
     *      time            String    (required)签名时间
     *      access_token    String    (required)用户访问接口的access_token
     *      integral		integer		(required)玩家积分
     *      integral_type	integer		(required)积分类型
     * @return array 返回一个JSON数组，结构如下：
     *      ret            Integer   成功or失败。0失败，１成功
     *      data		   mixed     查询成功返回数据
     *      msg            String    返回消息
     */
    public function upIntegralAction()
    {
    	$logger = $this->getServiceLocator()->get('Zend\Log');
    	$config = $this->getServiceLocator()->get('config');
    	$user   = $this->getServiceLocator()->get('User\Model\QQ');
    	
    	$data = json_decode($this->request->getContent(), 1);
    	$logger->info('Data from client(post):');
    	$logger->debug($data);
    	self::putLog("upIntegralAction————Data from client:");
    	self::putLog($data);
//     	$data['open_id'] = '664FF60DB9EA606B1E241355A2C943B5';
//     	$data['time'] = '1423051029';
//     	$data['access_token'] = 'AC82AF926EADFFB150F349B8B4CDBDF6';
//     	$data['integral'] = 3213234;
//     	$data['integral_type'] = 0;
    	
    	$return = array();
    	$link = $this -> connectDb();
    	
    	if(isset($data['integral']) && isset($data['integral_type']))
    	{
    		if(!$user->checkToken($data['open_id'], $data['time'], $data['access_token']))
    		{
    			self::putLog("token invalid");
    			$return['ret'] = 0;
    			$return['msg'] = "token invalid";
    			echo json_encode($return);
    			exit;
    		}else{
    			$result = $link->query("select integral,openid from AQQ_FRIENDS_TBL where openid='{$data['open_id']}'");
    			$result = mysqli_fetch_assoc($result);
    			if($result['openid']){
	    			//数据库没有数据时处理
	    			if(!$result['integral']){
	    				$result['integral'] = "0-0-0-0-0";
	    			}
	    			$integral_array = explode('-', $result['integral']);
	    			if($integral_array[$data['integral_type']] < $data['integral'])
	    			{
	    				$integral_array[$data['integral_type']] = $data['integral'];
	    				
	    			}
	    			$integral_array = join('-', $integral_array);
	    			$flag = $link->query("update AQQ_FRIENDS_TBL set integral='{$integral_array}' where openid='{$data['open_id']}'");
	    			if($flag)
	    			{
	    				$return['ret'] = 1;
	    				$return['msg'] = 'success';
	    			}else{
	    				$return['ret'] = 0;
	    				$return['msg'] = "update AQQ_FRIENDS_TBL error";
	    			}
    			}else{
    				$return['ret'] = 0;
    				$return['msg'] = "no this userinfo";
    			}
    		}
    	}else{
    		$return['ret'] = 0;
    		$return['msg'] = "integral invalid or integral_type invalid";
    	}
    	self::putLog("upIntegralAction--------------Data give client:");
    	self::putLog($return);
    	
    	mysqli_close($link);
    	echo json_encode($return);
    	exit;
    }
    /**
     * 数据库链接
     * @return 数据库链接句柄
     */
    public function connectDb()
    {
    	$adapter_name = "board_wx";//board_qq
    	$params = $this->getServiceLocator()->get($adapter_name) -> getDriver() -> getConnection() -> getConnectionParameters();
    	$username = $password = $hostname = $charset = $database = NULL;
    	$username = $params['username'];
    	$password = $params['password'];
    	$dsn = explode(';', $params['dsn']);
    	foreach ($dsn as $value) {
    		if (!empty($value)){
    			$value = explode('=', $value);
    			if(stripos($value[0], 'dbname') !== FALSE){
    				$database = $value[1];
    			}elseif($value[0] === 'host'){
    				$hostname = $value[1];
    			}elseif($value[0] == 'charset'){
    				$charset = $value[1];
    			}
    		}
    	}
    	
    	$link = mysqli_connect($hostname, $username, $password, $database) or die("Error " . mysqli_error($link));
    	mysqli_set_charset($link, $charset);
    	return $link;
    }
    /*--------------------------------------------------------------测试用日志及测试单例-------------------------------------------------------------------*/
    /**
     * 测试
     */
    public function testAction()
    {
    	$rs = json_decode('{"platform":"2","os":"1","open_id":"B26687C0A3E608AFFE368F28B4056502","flag":"0","pf_key":"f98207f979ed0cf42673bea7864c9b7d","access_token":"C32475EDF60206C0947693E44730566E","pf":"desktop_m_qq-73213123-android-73213123-qq-1000002010-B26687C0A3E608AFFE368F28B4056502","pay_token":"9DB406270C49103C8976FFB611726430"}', true);
    	print_r($rs);
    	exit;
    }
    /**
     * 测试记录日志
     */
    public function putLog($data)
    {
    	$dir = dirname(__FILE__);
    	$time = date("Y-m-d H:i:s", time());
    	
    	if(is_array($data))
    	{
    		$log = json_encode($data);
    	}else{
    		$log = $data;
    	}
    	file_put_contents($dir.'/log.txt', "\r\n".$time."--------------".$log, FILE_APPEND);
    }
    /**
     * 清除日志
     */
    public function clearLogAction()
    {
    	$dir = dirname(__FILE__);
    	echo file_put_contents($dir.'/log.txt', "");
    }
}
