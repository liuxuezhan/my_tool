<?php
return array(
		'router' => array(
		    'routes' => array(
		        'server' => array(
		            'type'    => 'segment',
		            'options' => array(
		                'route'    => '/server[/][:action][/:id]',
		                'constraints' => array(
		                    'action' => '[a-zA-Z][a-zA-Z0-9_-]*',
		                    'id'     => '[0-9]+',
		                ),
		                'defaults' => array(
		                    'controller' => 'Gateway\Controller\Server',
		                    'action'     => 'index',
		                ),
		            ),
		        ),
		        'iqq_board' => array(
		            'type'    => 'segment',
		            'options' => array(
		                'route'    => '/iqq/sns[/][:action][/:id]',
		                'constraints' => array(
		                    'action' => '[a-zA-Z][a-zA-Z0-9_-]*',
		                    'id'     => '[0-9]+',
		                ),
		                'defaults' => array(
		                    'controller' => 'Gateway\Controller\Board',
		                    'action'     => 'index',
		                ),
		            ),
		        ),
		        'aqq_board' => array(
		            'type'    => 'segment',
		            'options' => array(
		                'route'    => '/aqq/sns[/][:action][/:id]',
		                'constraints' => array(
		                    'action' => '[a-zA-Z][a-zA-Z0-9_-]*',
		                    'id'     => '[0-9]+',
		                ),
		                'defaults' => array(
		                    'controller' => 'Gateway\Controller\Board',
		                    'action'     => 'index',
		                ),
		            ),
		        ),
		        'iwx_board' => array(
		            'type'    => 'segment',
		            'options' => array(
		                'route'    => '/iwx/sns[/][:action][/:id]',
		                'constraints' => array(
		                    'action' => '[a-zA-Z][a-zA-Z0-9_-]*',
		                    'id'     => '[0-9]+',
		                ),
		                'defaults' => array(
		                    'controller' => 'Gateway\Controller\Board',
		                    'action'     => 'index',
		                ),
		            ),
		        ),
		        'awx_board' => array(
		            'type'    => 'segment',
		            'options' => array(
		                'route'    => '/awx/sns[/][:action][/:id]',
		                'constraints' => array(
		                    'action' => '[a-zA-Z][a-zA-Z0-9_-]*',
		                    'id'     => '[0-9]+',
		                ),
		                'defaults' => array(
		                    'controller' => 'Gateway\Controller\Board',
		                    'action'     => 'index',
		                ),
		            ),
		        ),
				    
		    ),
		),
		'controllers' => array(
		    'invokables' => array(
 		        'Gateway\Controller\Server'      => 'Gateway\Controller\ServerController',
		        'Gateway\Controller\Board'       => 'Gateway\Controller\BoardController',
		    ),
		),
		'view_manager' => array(
		    'template_map'    => include __DIR__ . '/../template_map.php',
		    'strategies'      => array(
		        'ViewJsonStrategy',
		    ),
// 		    'template_path_stack' => array(
// 		        'gateway' => __DIR__ . '/../view',
// 		    ),
 		),
);