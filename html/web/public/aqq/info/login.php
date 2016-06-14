<?php
header("Content-type: text/html; charset=utf-8");
define('VENDOR_YX_ROOT', '.'. DIRECTORY_SEPARATOR .'yuxiang' . DIRECTORY_SEPARATOR);
define('VENDOR_TX_ROOT', '.'. DIRECTORY_SEPARATOR . 'tencent' . DIRECTORY_SEPARATOR);
define('CONFIG_ROOT', '.'. DIRECTORY_SEPARATOR . 'config' . DIRECTORY_SEPARATOR);
define('LOG_ROOT', '.' . DIRECTORY_SEPARATOR. 'logs' . DIRECTORY_SEPARATOR);

require_once VENDOR_YX_ROOT . 'logger.php';
require_once VENDOR_YX_ROOT . 'socket_api.php';

require_once 'config/application.config.php';
// $logger = Logger::getInstance();

/**
 * 测试记录日志
 */
function putLog($data)
{
	$dir = dirname(__FILE__).DIRECTORY_SEPARATOR.'logs'.DIRECTORY_SEPARATOR.'log.txt';
	$time = date("Y-m-d H:i:s", time());

	if(is_array($data))
	{
		$log = json_encode($data);
	}else{
		$log = $data;
	}
	file_put_contents($dir, "\r\n".$time."--------------".$log, FILE_APPEND);
}

$return = array();

require('QQ.php');

$user   = new QQ(QQ_APPID,QQ_APPKEY);

$return['time_get_data_from_client'] = microtime();

$post = $_POST;

$data = array_keys($post);
$data = json_decode($data[0], true);
// print_r($data);

$return['data'] = $data;

$return['time_json_end'] = microtime();

// $return['post'] = $post;

// $return['data_json_decode'] = $data;

$return['time_post_data_to_tx'] = microtime();

if (($ret = $user->store($data)) === true) {
	$result = $user->getProfile($data);
	if ($result['ret'] === CX_CODE_SUCCESS) {
		$r_data = $result['data'];
		if ($r_data['ret'] === TX_CODE_SUCCESS) {
			//签名,格式：openid+time+自定义字符串
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
        
$return['response'] = $response;

$return['time_get_data_from_tx'] = microtime();

putLog($return);

echo json_encode($return);
exit;
    
