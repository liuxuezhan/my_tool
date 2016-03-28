<?php
namespace Gateway\Controller;

use Zend\Mvc\Controller\AbstractActionController;
use Zend\View\Model\JsonModel;

use Gateway\Model\Board;

class BoardController extends AbstractActionController
{
    private $boardTableWX;
    private $boardTableQQ;

    private function getBoardTableWX()
    {
        if (!$this->boardTableWX) {
            $this->boardTableWX = $this->getServiceLocator()->get('Gateway\Model\BoardTableWX');
        }
        return $this->boardTableWX;
    }
    
    private function getBoardTableQQ()
    {
        if (!$this->boardTableQQ) {
            $this->boardTableQQ = $this->getServiceLocator()->get('Gateway\Model\BoardTableQQ');
        }
        return $this->boardTableQQ;
    }
    
    public function indexAction()
    {
        return new JsonModel(array(
            'data'  => 'This page is forbidden!',
        ));
    }
    
    /**
     * 取得用户好友关系链（项目组自定关系链）
     * @param array  通过HTTP POST方式提交数据，数据字段定义如下：
     *      open_ids        String    (required)以;分隔的OpenIDs
     *      area_id         Integer   (required)腾讯平台定义。定义如下：１.微信，２.QQ
     *      platform        Integer   (required)客户端操作系统定义。0: iOS, 1: Android
     *      ts              Integer   (required)提交的时间戳
     *      sig             String    (required)签名
     * @return array 返回一个JSON数组，结构如下：
     *      ret             Integer   成功or失败。0失败，１成功
     *      msg             String    返回消息
     *      data            Mixed     返回数据
     */
    public function readAction()
    {
        $logger     = $this->getServiceLocator()->get('Zend\Log');
        $config     = $this->getServiceLocator()->get('config');
        
        $data = $this->params()->fromPost();
        $logger->debug($data);
        if (!empty($data['open_ids']) && isset($data['platform']) && isset($data['area_id']) && !empty($data['ts']) && !empty($data['sig'])) {
            $open_ids = explode(';', $data['open_ids']);
            $cnt = count($open_ids);
            $sig = Board::makeCxSignature(array(
                $cnt,
                $data['area_id'],
                $data['platform'],
                $data['ts'],
                Board::CX_SIG_RELATION_KEY,
            ), $logger);
            
            if ($data['sig'] !== $sig) {
                $response = Board::formatResponse(Board::CX_CODE_FAILED, 'Bad signature!', null);
            } else {
                unset($data['sig'], $data['ts']);
                
                if ($data['area_id'] == Board::ePlatform_Weixin) {
                    $ret = $this->getBoardTableWX()->getBoard($open_ids, $data['platform']);
                } elseif ($data['area_id'] == Board::ePlatform_QQ) {
                    $ret = $this->getBoardTableQQ()->getBoard($open_ids, $data['platform']);
                } else {
                    $ret = 0;
                }
                $logger->debug((array)$ret);
                
                $response = $ret === 0 ? Board::formatResponse(Board::CX_RETURN_FAILED, 'Unsupport area_id', $ret) : Board::formatResponse(Board::CX_CODE_SUCCESS, 'success', $ret);
            }
        } else {
            $response = Board::formatResponse(Board::CX_CODE_FAILED, 'Invalid data!', null);
        }
        
        echo json_encode($response);
        exit;
    }
    
    /**
     * 存储用户好友关系链（项目组自定关系链）
     * @param array  通过HTTP POST方式提交数据，数据字段定义如下：
     *      open_ids        String    (required)以;分隔的OpenIDs
     *      area_id         Integer   (required)腾讯平台定义。定义如下：１.微信，２.QQ
     *      platform        Integer   (required)客户端操作系统定义。0: iOS, 1: Android
     *      **              **        (Optional)需要更新的数据字段，与数据库字段一致，请参见数据表定义
     *      ts              Integer   (required)提交的时间戳
     *      sig             String    (required)签名
     * @return array 返回一个JSON数组，结构如下：
     *      ret             Integer   成功or失败。0失败，１成功
     *      msg             String    返回消息
     *      data            Mixed     返回数据
     */
    public function updateAction()
    {
        $logger     = $this->getServiceLocator()->get('Zend\Log');
        $config     = $this->getServiceLocator()->get('config');
        
        $data = $this->params()->fromPost();
        if (!empty($data['open_id']) && isset($data['platform']) && isset($data['area_id']) && !empty($data['ts']) && !empty($data['sig'])) {
            $sig = Board::makeCxSignature(array(
                $data['open_id'],
                $data['area_id'],
                $data['platform'],
                $data['ts'],
                Board::CX_SIG_RELATION_KEY,
            ));
            
            if ($data['sig'] !== $sig) {
                $response = Board::formatResponse(Board::CX_CODE_FAILED, 'Bad signature!', null);
            } else {
                $area_id = $data['area_id'];
                unset($data['sig'], $data['ts'], $data['area_id']);
                
                if ($area_id == Board::ePlatform_Weixin) {
                    $ret = $this->getBoardTableWX()->saveBoard($data);
                } elseif ($area_id == Board::ePlatform_QQ) {
                    $ret = $this->getBoardTableQQ()->saveBoard($data);
                } else {
                    $ret = 0;
                }
                $response = $ret > 0 ? Board::formatResponse(Board::CX_CODE_SUCCESS, 'success', null) : Board::formatResponse(Board::CX_CODE_FAILED, 'Update failed', null);
            }
        } else {
            $response = Board::formatResponse(Board::CX_CODE_FAILED, 'Invalid data!', null);
        }
        
        echo json_encode($response);
        exit;
    }
    
}