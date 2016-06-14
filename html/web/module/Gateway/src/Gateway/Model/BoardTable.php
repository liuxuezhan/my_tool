<?php
namespace Gateway\Model;

use Zend\Db\TableGateway\TableGateway;
use Application\Model\Application;

class BoardTable extends Application
{
    protected $tableGateway;
    
    public function __construct(TableGateway $tableGateway)
    {
        $this->tableGateway = $tableGateway;
    }
    
    public function fetchAll()
    {
        $resultSet = $this->tableGateway->select();
        return $resultSet;
    }
    
    public function getBoard($openid, $pf)
    {
        $ret = array();
         
        $rowset = $this->tableGateway->select(array('open_id' => $openid, 'platform' => $pf));
        $cnt = count($rowset);
        if ($cnt > 0) {
            foreach ($rowset as $row) {
                $ret[$row->open_id] = (array) $row;
            }
        }
    
        return $ret;
    }
    
    public function saveBoard($data)
    {
        $u = $this->getBoard($data['open_id'], $data['platform']);
        if (!$u) {
            $this->tableGateway->insert($data);
            $ret = 1;
        } else {
            $this->tableGateway->update($data, array('open_id' => $data['open_id'], 'platform' => $data['platform']));
            $ret = 2;
        }
    
        return $ret;
    }
    
    public function deleteBoard($openid, $pf)
    {
        $this->tableGateway->delete(array('open_id' => $openid, 'platform' => $pf));
    }
}