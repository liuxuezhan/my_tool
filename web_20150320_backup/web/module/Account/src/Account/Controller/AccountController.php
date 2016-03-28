<?php
namespace Account\Controller;

use Zend\Mvc\Controller\AbstractRestfulController;
use Zend\View\Model\JsonModel;
use Zend\Db\Adapter\Adapter;

use Account\Model\Account;
use Zend\Db\Sql\Ddl\Column\Integer;

class AccountController extends AbstractRestfulController
{
    public function indexAction()
    {
        return new JsonModel(array(
            'data'   => 'This page is forbidden!',
        ));;
    }
    
    /**
     * 取得帐户余额接口
     * @param array  通过HTTP RAW POST方式提交数据，数据字段定义如下：
     *      platform        Integer   (required)腾讯平台定义。定义如下：１.微信，２.QQ，３.WT。４.QQ大厅。５.游客模式
     *      os              Integer   (required)客户端操作系统定义。0: iOS, 1: Android
     *      open_id         String    (required)用户openID
     *      access_token    String    (required)用户访问接口的access_token
     *      pf              String    (required)腾讯pf定义
     *      pf_key          String    (required)腾讯pf_key定义
     *      zoneid          Integer   (required)腾讯zoneid定义
     *      pay_token       String    (required)腾讯pay_token定义
     * @return array 返回一个JSON数组，结构如下：
     *      ret             Integer   成功or失败。0失败，１成功
     *      msg             String    返回消息
     *      data            Mixed     返回数据，如果成功，返回格式如下：
     *          balance         Integer 游戏币个数
     *          gen_balance     Integer 赠送游戏币个数
     *          first_save      Bool    是否满足首次充值，1：满足，0：不满足
     *          save_amt        Integer 累计充值金额
     *          time            Integer 当前时间戳
     *          flag            String  该数据包的签名
     */
    public function balanceAction()
    {
        $logger = $this->getServiceLocator()->get('Zend\Log');
        $config = $this->getServiceLocator()->get('config');
        $user   = $this->getServiceLocator()->get('Account\Model\Account');
    
        $data = json_decode($this->request->getContent(), true);
        $logger->info('Data from client(post):');
        $logger->debug($data);
    
        if (($ret = $user->store($data)) === true) {
            $result = $user->getBalance($data);
            if ($result['ret'] === Account::CX_CODE_SUCCESS) {
                $r_data = $result['data'];
                if ($r_data['ret'] === Account::TX_CODE_SUCCESS) {
                    $sig = Account::makeCxSignature(array(
                        $user->zoneid,
                        $user->openid,
                        $r_data['balance'],
                        $r_data['save_amt'],
                        Account::CX_PAY_KEY,
                    ));
                    $rdata = $user->signCxResponse(array(
                        'balance'       => $r_data['balance'],
                        'gen_balance'   => $r_data['gen_balance'],
                        'first_save'    => $r_data['first_save'],
                        'save_amt'      => $r_data['save_amt'],
                        'tss_list'      => isset($r_data['tss_list']) ? $r_data['tss_list'] : null,
                        'flag'          => $sig,
                    ));
                    $logger->debug($rdata);
                    $response = Account::formatResponse(Account::CX_CODE_SUCCESS, 'success', $rdata);
                } else {//MSDK Return result error
                    $response = Account::formatResponse(Account::CX_CODE_FAILED, 'MSDK return error!', $r_data);
                }
            } else {//MSDK Http response error
                $response = Account::formatResponse($result);
            }
        } else {//Data validation failed
            $response = Account::formatResponse(Account::CX_CODE_FAILED, 'Data posted from client is invalid!', $ret);
        }
    
        //output
        //return new JsonModel($response);
        echo json_encode($response);
        exit;
    }
    
    /**
     * QQ/wx帐户扣减操作
     * @param data  通过HTTP RAW POST方式提交数据，数据字段定义如下：
     *      platform        Integer   (required)腾讯平台定义。定义如下：１.微信，２.QQ，３.WT。４.QQ大厅。５.游客模式
     *      os              Integer   (required)客户端操作系统定义。0: iOS, 1: Android
     *      open_id         String    (required)用户openID
     *      access_token    String    (required)用户访问接口的access_token
     *      pf              String    (required)腾讯pf定义
     *      pf_key          String    (required)腾讯pf_key定义
     *      zoneid          Integer   (required)腾讯zoneid定义
     *      pay_token       String    (required)腾讯pay_token定义
     *      amt             Integer   (required)扣减金额（可能为浮点型，根据实际情况定）
     *      payitem         String    (Optional)扣减金额用于购买什么道具
     * @return array 返回一个JSON数组，结构如下：
     *      ret             Integer   成功or失败。0失败，１成功
     *      msg             String    返回消息
     *      data            Mixed     返回数据，如果成功，返回格式如下：
     *          ret             Integer 腾讯的返回代码
     *          openid          String  用户的OpenID
     *          billno          String  此次交易号
     *          amt             Integer 此次扣减金额
     *          balance         Integer 用户剩余游戏币个数
     *          time            Integer 当前时间戳  
     *          flag            String  该数据包的签名
     */
    public function payAction()
    {
        $logger = $this->getServiceLocator()->get('Zend\Log');
        $config = $this->getServiceLocator()->get('config');
        $user   = $this->getServiceLocator()->get('Account\Model\Account');
        
        $data = json_decode($this->request->getContent(), true);
        $logger->info('Data from client(post):');
        $logger->debug($data);
        
        if (($ret = $user->store($data)) === true) {
            $result = $user->pay($data);
            if ($result['ret'] === Account::CX_CODE_SUCCESS) {
                $r_data = $result['data'];
                if ($r_data['ret'] === Account::TX_CODE_SUCCESS) {
                    $sig = Account::makeCxSignature(array(
                        $user->openid,
                        $r_data['billno'],
                        $data['amt'],
                        $r_data['balance'],
                        Account::CX_PAY_KEY,
                    ), $logger);
                    $rdata = $user->signCxResponse(array(
                        'ret'           => $r_data['ret'],
                        'openid'        => $data['open_id'],
                        'billno'        => $r_data['billno'],
                        'amt'           => $data['amt'],
                        'balance'       => $r_data['balance'],
                        'flag'          => $sig,
                    ));
                    $response = Account::formatResponse(Account::CX_CODE_SUCCESS, 'success', $rdata);
                    
                    //send GM command to GS
                    //根据area_id/plat_id/partition查找数据库连接
                    $adapter_name = "gateway";
                    $adapter = $this->getServiceLocator()->get($adapter_name);
                    
                    $sql = "SELECT ip, port, db_host, db_port, db_name, db_user, db_pass, status FROM servers WHERE area_id = {$data['platform']} AND plat_id = {$data['os']} AND partition = {$data['zoneid']}";
                    $logger->info("execute sql: $sql");
                    $result = $adapter->query($sql, Adapter::QUERY_MODE_EXECUTE);
                    $logger->debug('find db info on gateway');
                    //$logger->debug(print_r($result, true));
                    
                    if (!empty($result)) {
                        $gs_config = array();
                        foreach ($result as $row) {
                            $gs_config['status'] = $row['status'];
                            $gs_config['host'] = $row['db_host'];
                            $gs_config['port'] = $row['db_port'];
                            $gs_config['name'] = $row['db_name'];
                            $gs_config['user'] = $row['db_user'];
                            $gs_config['pass'] = $row['db_pass'];
                    
                            $gs_config['gs_ip'] = $row['ip'];
                            $gs_config['gs_port'] = $row['port'];
                        }
                        
                        $gm_result = Account::sendGMCmd($response, $gs_config['gs_ip'], $gs_config['gs_port'], false);
                        $logger->debug($gm_result);
                    }
                } else {//MSDK Return result error
                    $response = Account::formatResponse(Account::CX_CODE_FAILED, 'MSDK return error!', $r_data);
                }
            } else {//MSDK Http response error
                $response = Account::formatResponse($result);
            }
        } else {//Data validation failed
            $response = Account::formatResponse(Account::CX_CODE_FAILED, 'Data posted from client is invalid!', $ret);
        }
        
        $logger->debug($response);
        //output
        //return new JsonModel($response);
        echo json_encode($response);
        exit;
    }
    
    /**
     * QQ/wx帐户取消扣减操作
     * @param data  通过HTTP RAW POST方式提交数据，数据字段定义如下：
     *      platform        Integer   (required)腾讯平台定义。定义如下：１.微信，２.QQ，３.WT。４.QQ大厅。５.游客模式
     *      os              Integer   (required)客户端操作系统定义。0: iOS, 1: Android
     *      open_id         String    (required)用户openID
     *      access_token    String    (required)用户访问接口的access_token
     *      pf              String    (required)腾讯pf定义
     *      pf_key          String    (required)腾讯pf_key定义
     *      zoneid          Integer   (required)腾讯zoneid定义
     *      pay_token       String    (required)腾讯pay_token定义
     *      amt             Integer   (required)取消扣减金额（可能为浮点型，根据实际情况定）
     *      billno          String    (required)此次交易号
     * @return array 返回一个JSON数组，结构如下：
     *      ret             Integer   成功or失败。0失败，１成功
     *      msg             String    返回消息
     *      data            Mixed     返回数据，如果成功，返回格式如下：
     *          ret             Integer 腾讯的返回代码
     *          time            Integer 当前时间戳
     *          flag            String  该数据包的签名
     */
    public function cancelPayAction()
    {
        $logger = $this->getServiceLocator()->get('Zend\Log');
        $config = $this->getServiceLocator()->get('config');
        $user   = $this->getServiceLocator()->get('Account\Model\Account');
        
        $data = json_decode($this->request->getContent(), true);
        $logger->info('Data from client(post):');
        $logger->debug($data);
        
        if (($ret = $user->store($data)) === true) {
            $result = $user->cancelPay($data);
            if ($result['ret'] === Account::CX_CODE_SUCCESS) {
                $r_data = $result['data'];
                if ($r_data['ret'] === Account::TX_CODE_SUCCESS) {
                    $rdata = $user->signCxResponse(array(
                        'ret'           => $r_data['ret'],
                    ));
                    $response = Account::formatResponse(Account::CX_CODE_SUCCESS, 'success', $rdata);
        
                    //send GM command to GS
                    //根据area_id/plat_id/partition查找数据库连接
                    $adapter_name = "gateway";
                    $adapter = $this->getServiceLocator()->get($adapter_name);
                    
                    $sql = "SELECT ip, port, db_host, db_port, db_name, db_user, db_pass, status FROM servers WHERE area_id = {$data['platform']} AND plat_id = {$data['os']} AND partition = {$data['zoneid']}";
                    $logger->info("execute sql: $sql");
                    $result = $adapter->query($sql, Adapter::QUERY_MODE_EXECUTE);
                    $logger->debug('find db info on gateway');
                    //$logger->debug(print_r($result, true));
                    
                    if (!empty($result)) {
                        $gs_config = array();
                        foreach ($result as $row) {
                            $gs_config['status'] = $row['status'];
                            $gs_config['host'] = $row['db_host'];
                            $gs_config['port'] = $row['db_port'];
                            $gs_config['name'] = $row['db_name'];
                            $gs_config['user'] = $row['db_user'];
                            $gs_config['pass'] = $row['db_pass'];
                    
                            $gs_config['gs_ip'] = $row['ip'];
                            $gs_config['gs_port'] = $row['port'];
                        }
                    
                        $gm_result = Account::sendGMCmd($response, $gs_config['gs_ip'], $gs_config['gs_port'], false);
                        $logger->debug($gm_result);
                    }
                } else {//MSDK Return result error
                    $response = Account::formatResponse(Account::CX_CODE_FAILED, 'MSDK return error!', $r_data);
                }
            } else {//MSDK Http response error
                $response = Account::formatResponse($result);
            }
        } else {//Data validation failed
            $response = Account::formatResponse(Account::CX_CODE_FAILED, 'Data posted from client is invalid!', $ret);
        }
        
        //output
        //return new JsonModel($response);
        echo json_encode($response);
        exit;
    }

}