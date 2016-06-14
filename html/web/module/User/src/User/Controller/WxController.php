<?php
namespace User\Controller;

use Zend\Mvc\Controller\AbstractRestfulController;
use Zend\View\Model\JsonModel;

use User\Model\WX;

class WxController extends AbstractRestfulController
{
    
    public function indexAction()
    {
        return new JsonModel(array(
            'data'  => 'This page is forbidden!',
        ));
    }
    
    /**
     * 取得WX用户帐户信息接口
     * @param array  通过HTTP RAW POST方式提交数据，数据字段定义如下：
     *      platform        Integer   (required)腾讯平台定义。定义如下：１.微信，２.QQ，３.WT。４.QQ大厅。５.游客模式，此处只能为1
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
        $logger = $this->getServiceLocator()->get('Zend\Log');
        $config = $this->getServiceLocator()->get('config');
        $user   = $this->getServiceLocator()->get('User\Model\WX');
    
        $data = json_decode($this->request->getContent(), true);
        $logger->info('Data from client(post):');
        $logger->debug($data);
    
        if (($ret = $user->store($data)) === true) {
            $result = $user->getProfile($data);
            if ($result['ret'] === WX::CX_CODE_SUCCESS) {
                $r_data = $result['data'];
                $logger->debug($r_data);
                if ($r_data['ret'] === WX::TX_CODE_SUCCESS) {
                    $rdata = $user->signCxResponse(array(
                        'user_name' => $r_data['nickname'],
                        'user_id'   => $user->openid,
                    ));
                    $response = WX::formatResponse(WX::CX_CODE_SUCCESS, 'success', $rdata);
                } else {//MSDK Return result error
                    $response = WX::formatResponse(WX::CX_CODE_FAILED, 'MSDK return error!', $r_data);
                }
            } else {//MSDK Http response error
                $response = WX::formatResponse($result);
            }
        } else {//Data validation failed
            $response = WX::formatResponse(WX::CX_CODE_FAILED, 'Data posted from client is invalid!', $ret);
        }
    
        //output
        //return new JsonModel($response);
        echo json_encode($response);
        exit;
    }
    
    /**
     * 取得WX用户好友列表
     * @param array  通过HTTP RAW POST方式提交数据，数据字段定义如下：
     *      platform        Integer   (required)腾讯平台定义。定义如下：１.微信，２.QQ，３.WT。４.QQ大厅。５.游客模式，此处只能为1
     *      os              Integer   (required)客户端操作系统定义。0: iOS, 1: Android
     *      open_id         String    (required)用户openID
     *      access_token    String    (required)用户访问接口的access_token
     * @return array 返回一个JSON数组，结构如下：
     *      ret             Integer   成功or失败。0失败，１成功
     *      msg             String    返回消息
     *      data            Mixed     返回数据，如果成功，返回格式如下：
     *          lists           List    好友信息列表
     *          privilege       Array   用户特权信息
     *          time            Integer 当前时间戳
     *          flag            String  该数据包的签名
     */
    public function friendsAction()
    {
        $logger = $this->getServiceLocator()->get('Zend\Log');
        $config = $this->getServiceLocator()->get('config');
        $user   = $this->getServiceLocator()->get('User\Model\WX');
    
        $data = json_decode($this->request->getContent(), true);
        $logger->info('Data from client(post):');
        $logger->debug($data);
    
        if (($ret = $user->store($data)) === true) {
            $result = $user->getFriendsOpenIds($data);
            if ($result['ret'] === WX::CX_CODE_SUCCESS) {
                $r_data = $result['data'];
                $logger->debug($r_data);
                if ($r_data['ret'] === WX::TX_CODE_SUCCESS) {
                    $result2 = $user->getFriendsInfo(array(
                        'openids'   => $r_data['openids'],
                    ));
                    if ($result2['ret'] === WX::CX_CODE_SUCCESS) {
                        $r_data2 = $result2['data'];
                        $logger->debug($r_data2);
                        if ($r_data2['ret'] === WX::TX_CODE_SUCCESS) {
                            $rdata = $user->signCxResponse(array(
                                'lists'     => $r_data2['lists'],
                                'privilege' => $r_data2['privilege'],
                            ));
                            $response = WX::formatResponse(WX::CX_CODE_SUCCESS, 'success', $rdata);
                        } else {//MSDK Return result error
                            $response = WX::formatResponse(WX::CX_CODE_FAILED, 'MSDK return error!(step 2)', $r_data);
                        }
                    } else {//MSDK Http response error
                        $result2['msg'] = $result2['msg'] . '(step 2)';
                        $response = WX::formatResponse($result2);
                    }
                    
                } else {//MSDK Return result error
                    $response = WX::formatResponse(WX::CX_CODE_FAILED, 'MSDK return error!(step 1)', $r_data);
                }
            } else {//MSDK Http response error
                $result['msg'] = $result['msg'] . '(step 1)';
                $response = WX::formatResponse($result);
            }
        } else {//Data validation failed
            $response = WX::formatResponse(WX::CX_CODE_FAILED, 'Data posted from client is invalid!', $ret);
        }
    
        //output
        //return new JsonModel($response);
        echo json_encode($response);
        exit;
    }
    
    /**
     * 游客模式签权(WX)
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
        $user   = $this->getServiceLocator()->get('User\Model\WX');
    
        $data = json_decode($this->request->getContent(), true);
        $logger->info('Data from client(post):');
        $logger->debug($data);
    
        if (($ret = $user->store($data)) === true) {
            $result = $user->guestCheckToken($data);
            if ($result['ret'] === WX::CX_CODE_SUCCESS) {
                $r_data = $result['data'];
                if ($r_data['ret'] === WX::TX_CODE_SUCCESS) {
                    $rdata = $user->signCxResponse(array(
                        'user_name' => 'Guest',
                        'user_id'   => $user->openid,
                    ));
                    $response = WX::formatResponse(WX::CX_CODE_SUCCESS, 'success', $rdata);
                } else {//MSDK Return result error
                    $response = WX::formatResponse(WX::CX_CODE_FAILED, 'MSDK return error!', $r_data);
                }
            } else {//MSDK Http response error
                $response = WX::formatResponse($result);
            }
        } else {//Data validation failed
            $response = WX::formatResponse(WX::CX_CODE_FAILED, 'Data posted from client is invalid!', $ret);
        }
    
        //output
        //return new JsonModel($response);
        echo json_encode($response);
        exit;
    }
    

}