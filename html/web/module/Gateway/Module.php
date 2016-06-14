<?php
namespace Gateway;

use Zend\ModuleManager\Feature\AutoloaderProviderInterface;
use Zend\ModuleManager\Feature\ConfigProviderInterface;

use Gateway\Model\Server;
use Gateway\Model\ServerTable;
use Gateway\Model\Board;
use Gateway\Model\BoardTable;
use Zend\Db\ResultSet\ResultSet;
use Zend\Db\TableGateway\TableGateway;

class Module implements AutoloaderProviderInterface, ConfigProviderInterface
{
	public function getAutoloaderConfig()
	{
		return array(
				'Zend\Loader\ClassMapAutoloader' => array(
						__DIR__ . '/autoload_classmap.php',
				),
				'Zend\Loader\StandardAutoloader' => array(
						'namespaces' => array(
								__NAMESPACE__ => __DIR__ . '/src/' . __NAMESPACE__,
						),
				),
		);
	}

	public function getConfig()
	{
		return include __DIR__ . '/config/module.config.php';
	}
	
	public function getServiceConfig()
	{
		return array(
		    'factories' => array(
		        'Gateway\Model\ServerTable' =>  function($sm) {
		            $tableGateway = $sm->get('ServerTableGateway');
		            $table = new ServerTable($tableGateway);
		            return $table;
		        },
		        'ServerTableGateway' => function ($sm) {
		            $dbAdapter = $sm->get('gateway');
		            $resultSetPrototype = new ResultSet();
		            $resultSetPrototype->setArrayObjectPrototype(new Server());
		            return new TableGateway('servers', $dbAdapter, null, null);
		        },
		        'Gateway\Model\BoardTableWX' =>  function($sm) {
		            $tableGateway = $sm->get('BoardTableGatewayWX');
		            $table = new BoardTable($tableGateway);
		            return $table;
		        },
		        'BoardTableGatewayWX' => function ($sm) {
		            $dbAdapter = $sm->get('board_wx');
		            $resultSetPrototype = new ResultSet();
		            $resultSetPrototype->setArrayObjectPrototype(new Board());
		            return new TableGateway('RELATION_TBL', $dbAdapter, null, null);
		        },
		        'Gateway\Model\BoardTableQQ' =>  function($sm) {
		            $tableGateway = $sm->get('BoardTableGatewayQQ');
		            $table = new BoardTable($tableGateway);
		            return $table;
		        },
		        'BoardTableGatewayQQ' => function ($sm) {
		            $dbAdapter = $sm->get('board_qq');
		            $resultSetPrototype = new ResultSet();
		            $resultSetPrototype->setArrayObjectPrototype(new Board());
		            return new TableGateway('RELATION_TBL', $dbAdapter, null, null);
		        },
		        'Gateway\Model\Server'   => function ($sm) {
		            $config = $sm->get('config');
		            $server = new Server();
		            $server->setServiceLocator($sm);
		            return $server;
		        },
		    ),
		);
	}
	
}