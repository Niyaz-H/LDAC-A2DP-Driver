   M S B A M L   `   `   `  ����   LDACConfigApp!    LDACConfigApp.LDACConfigApp   W SPresentationCore, Version=6.0.2.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35\ XPresentationFramework, Version=6.0.2.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35e aSystem.Windows.Controls.Ribbon, Version=6.0.2.0, Culture=neutral, PublicKeyToken=b77a5c561934e089R NWindowsBase, Version=6.0.2.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35F 9http://schemas.microsoft.com/winfx/2006/xaml/presentation     R NSystem.Xaml, Version=6.0.2.0, Culture=neutral, PublicKeyToken=b77a5c561934e089:x,http://schemas.microsoft.com/winfx/2006/xaml     @d2http://schemas.microsoft.com/expression/blend/2008     Jmc;http://schemas.openxmlformats.org/markup-compatibility/2006       � Title$1  +Soundcore Space One NC - LDAC Configuration��$	��450��$	��600��.���  � RowDefinitions �� $
��Auto ��� $��* ��� $
��Auto �.+��� $��0�����	#FF0078D4 �� Padding$ 10q�._��� $/��)Soundcore Space One NC LDAC Configuration��$��18(�$
��Bold"�
�������� $��1��$��10q� �� $
��Auto ��� $��* ��� $
��Auto ��� $
��Auto �.+��� $��0��$��0,0,0,10q�.+��� $��Device Status:��$��14(�$
��Bold"��� -    ��Name$ 
StatusText��$��Checking devices...��$��12(��� -    ��Name$ DeviceListBox��$��1��$��0,0,0,10q����� .R��� .+��� $
��Bold"����� *Name+�� $��10(�
����������� *Status+�� $��10(�
����  ����� *	Address+�� $��2��$��0,0,0,10q�.+��� $��LDAC Configuration:��$
��Bold"�$��0,0,0,5q��� -    ��Name$ LDACEnabledCheck��$��Enable LDAC 990 kbps�� d� 	IsChecked$
 TrueY��� -   $ ForceLDACCheck��$��Force LDAC codec��$
 TrueY���  �� Orientation$ 
Horizontal=�$��0,10,0,0q�.+��� -    ��Name$ RefreshButton��$��Refresh Devices��$	��120��$��0,0,10,0q��� -   $ ApplyButton��$��Apply Settings��$	��120���� $��3��.@��� .���� -   $ StatusBarText��$��Ready��