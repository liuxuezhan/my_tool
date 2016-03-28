<?php
namespace Gateway\Model;

use Zend\Db\TableGateway\TableGateway;
use Application\Model\Application;

class ServerTable extends Application
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

	public function getServer($areaId, $platId = NULL, $partition = NULL)
	{
	    if (empty($platId) && empty($partition)) {//find by Id
	        $rowset = $this->tableGateway->select(array('id' => $areaId));
	    } else {//find by areaId & platId & partition
	        $rowset = $this->tableGateway->select(array('area_id' => $areaId, 'plat_id' => $platId, 'partition' => $partition));
	    }
	    $rowset->setArrayObjectPrototype(new Server());
		$row = $rowset->current();
		
		return $row;
	}

	public function getServers($cond)
	{
	    $rowset = $this->tableGateway->select($cond);
	    
	    return $rowset->toArray();
	}
	
	public function saveServer(Server $server)
	{
	    $data = array(
	        'id'           => $server->id,
	        'area_id'      => $server->area_id,
	        'plat_id'      => $server->plat_id,
	        'partition'    => $server->partition,
	        'name'         => $server->name,
	        'ip'           => $server->ip,
	        'port'         => $server->port,
	        'db_host'      => $server->db_host,
	        'db_port'      => $server->db_port,
	        'db_name'      => $server->db_name,
	        'db_user'      => $server->db_user,
	        'db_pass'      => $server->db_pass,
	        'open_time'    => $server->open_time,
	        'status'       => $server->status,
	        'ref_id'       => $server->ref_id,
	        'updated_at'   => $server->updated_at,
	    );
	    
	    if (isset($data['id']) && !empty($data['id'])) {
	        $server = $this->getServer($data['id']);
	    } elseif (isset($data['area_id']) && isset($data['plat_id']) && isset($data['partition'])) {
	        $server = $this->getServer($data['area_id'], $data['plat_id'], $data['partition']);
	    } else {
	        $ret = 0;
	    }
		if (!$server) {
			$this->tableGateway->insert($data);
			$ret = 1;
		} else {
			$this->tableGateway->update($data, array('id' => $data['id']));
			$ret = 2;
		}
		
		return $ret;
	}

	public function deleteServer($areaId, $platId = NULL, $partition = NULL)
	{
	    if (empty($platId) && empty($partition)) {//find by Id
	        $this->tableGateway->delete(array('id' => $areaId));
	    } else {//find by areaId & platId & partition
	        $this->tableGateway->delete(array('area_id' => $areaId, 'plat_id' => $platId, 'partition' => $partition));
	    }
	}
}