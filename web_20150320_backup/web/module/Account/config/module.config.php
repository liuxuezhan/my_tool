<?php
return array(
		'router' => array(
				'routes' => array(
				    'iqq_account' => array(
				        'type'    => 'segment',
				        'options' => array(
				            'route'    => '/iqq/account[/][:action][/:id]',
				            'constraints' => array(
				                'action' => '[a-zA-Z][a-zA-Z0-9_-]*',
				                'id'     => '[0-9]+',
				            ),
				            'defaults' => array(
				                'controller' => 'Account\Controller\Account',
				                'action'     => 'index',
				            ),
				        ),
				    ),
				    'aqq_account' => array(
				        'type'    => 'segment',
				        'options' => array(
				            'route'    => '/aqq/account[/][:action][/:id]',
				            'constraints' => array(
				                'action' => '[a-zA-Z][a-zA-Z0-9_-]*',
				                'id'     => '[0-9]+',
				            ),
				            'defaults' => array(
				                'controller' => 'Account\Controller\Account',
				                'action'     => 'index',
				            ),
				        ),
				    ),
				    'iwx_account' => array(
				        'type'    => 'segment',
				        'options' => array(
				            'route'    => '/iwx/account[/][:action][/:id]',
				            'constraints' => array(
				                'action' => '[a-zA-Z][a-zA-Z0-9_-]*',
				                'id'     => '[0-9]+',
				            ),
				            'defaults' => array(
				                'controller' => 'Account\Controller\Account',
				                'action'     => 'index',
				            ),
				        ),
				    ),
				    'awx_account' => array(
				        'type'    => 'segment',
				        'options' => array(
				            'route'    => '/awx/account[/][:action][/:id]',
				            'constraints' => array(
				                'action' => '[a-zA-Z][a-zA-Z0-9_-]*',
				                'id'     => '[0-9]+',
				            ),
				            'defaults' => array(
				                'controller' => 'Account\Controller\Account',
				                'action'     => 'index',
				            ),
				        ),
				    ),
		        ),
		),
		'controllers' => array(
				'invokables' => array(
						'Account\Controller\Account'      => 'Account\Controller\AccountController',
				),
		),
		'view_manager' => array(
		    'strategies'      => array(
		        'ViewJsonStrategy',
		    ),
// 				'template_path_stack' => array(
// 						'account' => __DIR__ . '/../view',
// 				),
 		),
);