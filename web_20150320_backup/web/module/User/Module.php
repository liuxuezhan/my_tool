<?php
namespace User;

use Zend\ModuleManager\Feature\AutoloaderProviderInterface;
use Zend\ModuleManager\Feature\ConfigProviderInterface;

use User\Model\Relation;
use User\Model\UserTable;
use Zend\Db\ResultSet\ResultSet;
use Zend\Db\TableGateway\TableGateway;
use User\Model\QQ;
use User\Model\WX;

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
		        'User\Model\QQ'   => function ($sm) {
		            $config = $sm->get('config');
		            $user = new QQ($config['platform'][QQ::ePlatform_QQ]['appid'], $config['platform'][QQ::ePlatform_QQ]['appkey']);
		            $user->setServiceLocator($sm);
		            return $user;
		        },
		        'User\Model\WX'   => function ($sm) {
		            $config = $sm->get('config');
		            $user = new WX($config['platform'][WX::ePlatform_Weixin]['appid'], $config['platform'][WX::ePlatform_Weixin]['appkey']);
		            $user->setServiceLocator($sm);
		            return $user;
		        },
		    ),
		);
	}
	
}