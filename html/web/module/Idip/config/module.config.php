<?php
return array(
		'router' => array(
				'routes' => array(
				    'qq_idip' => array(
				        'type'    => 'segment',
				        'options' => array(
				            'route'    => '/qq/idip[/][:action][/:id]',
				            'constraints' => array(
				                'action' => '[a-zA-Z][a-zA-Z0-9_-]*',
				                'id'     => '[0-9]+',
				            ),
				            'defaults' => array(
				                'controller' => 'Idip\Controller\Idip',
				                'action'     => 'index',
				            ),
				        ),
				    ),
				    'wx_idip' => array(
				        'type'    => 'segment',
				        'options' => array(
				            'route'    => '/wx/idip[/][:action][/:id]',
				            'constraints' => array(
				                'action' => '[a-zA-Z][a-zA-Z0-9_-]*',
				                'id'     => '[0-9]+',
				            ),
				            'defaults' => array(
				                'controller' => 'Idip\Controller\Idip',
				                'action'     => 'index',
				            ),
				        ),
				    ),
		        ),
		),
		'controllers' => array(
				'invokables' => array(
						'Idip\Controller\Idip'      => 'Idip\Controller\IdipController',
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