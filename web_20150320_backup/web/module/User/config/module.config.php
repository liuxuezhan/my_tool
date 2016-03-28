<?php
return array(
		'router' => array(
				'routes' => array(
				    'iqq_user' => array(
				        'type'    => 'segment',
				        'options' => array(
				            'route'    => '/iqq/user[/][:action][/:id]',
				            'constraints' => array(
				                'action' => '[a-zA-Z][a-zA-Z0-9_-]*',
				                'id'     => '[0-9]+',
				                'format' => 'json',
				            ),
				            'defaults' => array(
				                'controller' => 'User\Controller\Qq',
				                'action'     => 'index',
				                'format'     => 'json',
				            ),
				        ),
				    ),
				    'aqq_user' => array(
				        'type'    => 'segment',
				        'options' => array(
				            'route'    => '/aqq/user[/][:action][/:id]',
				            'constraints' => array(
				                'action' => '[a-zA-Z][a-zA-Z0-9_-]*',
				                'id'     => '[0-9]+',
				                'format' => 'json',
				            ),
				            'defaults' => array(
				                'controller' => 'User\Controller\Qq',
				                'action'     => 'index',
				                'format'     => 'json',
				            ),
				        ),
				    ),
				    'iwx_user' => array(
				        'type'    => 'segment',
				        'options' => array(
				            'route'    => '/iwx/user[/][:action][/:id]',
				            'constraints' => array(
				                'action' => '[a-zA-Z][a-zA-Z0-9_-]*',
				                'id'     => '[0-9]+',
				            ),
				            'defaults' => array(
				                'controller' => 'User\Controller\Wx',
				                'action'     => 'index',
				            ),
				        ),
				    ),
				    'awx_user' => array(
				        'type'    => 'segment',
				        'options' => array(
				            'route'    => '/awx/user[/][:action][/:id]',
				            'constraints' => array(
				                'action' => '[a-zA-Z][a-zA-Z0-9_-]*',
				                'id'     => '[0-9]+',
				            ),
				            'defaults' => array(
				                'controller' => 'User\Controller\Wx',
				                'action'     => 'index',
				            ),
				        ),
				    ),
				),
		),
		'controllers' => array(
				'invokables' => array(
						'User\Controller\Qq'      => 'User\Controller\QqController',
				        'User\Controller\Wx'      => 'User\Controller\WxController',
				),
		),
    'service_manager' => array(
        'abstract_factories' => array(
            'Zend\Db\Adapter\AdapterAbstractServiceFactory',
        ),
    ),
		'view_manager' => array(
		    'strategies'      => array(
		          'ViewJsonStrategy',
		    ),
// 				'template_path_stack' => array(
// 						'qq' => __DIR__ . '/../view',
// 				        'wx' => __DIR__ . '/../view',
// 				),
		),
);