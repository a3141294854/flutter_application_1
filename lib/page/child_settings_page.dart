import 'package:flutter/material.dart';
import '../protocol/protocol.dart';
import '../theme/app_theme.dart';

class ChildSettingsPage extends StatefulWidget {
  final bool isConnected;
  final DtuService dtuService;
  const ChildSettingsPage({super.key, required this.isConnected, required this.dtuService});
  @override State<ChildSettingsPage> createState() => _ChildSettingsPageState();
}

class _ChildSettingsPageState extends State<ChildSettingsPage> {
  DtuService get _service => widget.dtuService;
  int _baudLevel = 0x03; int _dataBits = 0x08; int _parity = DtuProtocol.PARITY_NONE; int _stopBits = DtuProtocol.STOP_BITS_1;
  final List<int> _modbusAddresses = [1,2,3,4,5,6,7,8];
  final List<int> _modbusDeviceTypes = [5,5,5,5,5,5,5,5];
  bool _isLoading = false; bool _hasChanges = false;
  final _baudRates = [{'label':'1200','value':0x00},{'label':'2400','value':0x01},{'label':'4800','value':0x02},{'label':'9600','value':0x03},{'label':'19200','value':0x04},{'label':'38400','value':0x05},{'label':'57600','value':0x06},{'label':'115200','value':0x07}];
  final _dataBitsList = ['7','8'];
  final _parityList = [{'label':'None','value':DtuProtocol.PARITY_NONE},{'label':'Odd','value':DtuProtocol.PARITY_ODD},{'label':'Even','value':DtuProtocol.PARITY_EVEN}];
  final _stopBitsList = ['1','2'];
  final _deviceTypeOptions = [{'label':'其他预留','value':DtuProtocol.DEV_TYPE_RESERVED},{'label':'三相电表','value':DtuProtocol.DEV_TYPE_THREE_PHASE_METER},{'label':'单相电表','value':DtuProtocol.DEV_TYPE_SINGLE_PHASE_METER},{'label':'温湿度变送器','value':DtuProtocol.DEV_TYPE_TEMP_HUMIDITY},{'label':'继电器','value':DtuProtocol.DEV_TYPE_RELAY}];

  @override void initState() { super.initState(); if(widget.isConnected) WidgetsBinding.instance.addPostFrameCallback((_)=>_safeReadConfig()); }
  Future<void> _safeReadConfig() async { try{await _readConfig();}catch(e){} }
  @override void didUpdateWidget(ChildSettingsPage o) { super.didUpdateWidget(o); if(!o.isConnected&&widget.isConnected) _readConfig(); }

  Future<void> _readConfig() async {
    if(!widget.isConnected) return; setState(()=>_isLoading=true);
    try{
      final c=await _service.readAllConfig();
      setState((){
        if(c.uartConfig!=null){ _baudLevel=c.uartConfig!.baudLevel; _dataBits=c.uartConfig!.dataBits; _parity=c.uartConfig!.parity; _stopBits=c.uartConfig!.stopBits; }
        _resetModbusConfigToDefault();
        if(c.modbusConfig!=null&&c.modbusConfig!.items.isNotEmpty) for(int i=0;i<c.modbusConfig!.items.length&&i<8;i++){ _modbusAddresses[i]=c.modbusConfig!.items[i].addr; _modbusDeviceTypes[i]=c.modbusConfig!.items[i].devType; }
        _hasChanges=false;
      });
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('配置读取成功'),backgroundColor:NeuTheme.success));
    }catch(e){ if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('读取失败:$e'),backgroundColor:NeuTheme.error)); }
    finally{ setState(()=>_isLoading=false); }
  }

  Future<void> _saveConfig() async {
    if(!widget.isConnected||!_hasChanges) return; setState(()=>_isLoading=true);
    try{ await _service.writeAllConfig(uartConfig:UartConfig(baudLevel:_baudLevel,parity:_parity,stopBits:_stopBits,dataBits:_dataBits),modbusConfig:ModbusConfig(items:List.generate(8,(i)=>ModbusItem(addr:_modbusAddresses[i],devType:_modbusDeviceTypes[i])))); setState(()=>_hasChanges=false);
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('配置保存成功'),backgroundColor:NeuTheme.success)); }
    catch(e){ if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('保存失败:$e'),backgroundColor:NeuTheme.error)); }
    finally{ setState(()=>_isLoading=false); }
  }

  String _getBaudRateLabel()=>_baudRates.firstWhere((b)=>b['value']==_baudLevel,orElse:()=>_baudRates[3])['label'] as String;
  String _getParityLabel()=>_parityList.firstWhere((p)=>p['value']==_parity,orElse:()=>_parityList[0])['label'] as String;
  String _getDeviceTypeLabel(int t)=>_deviceTypeOptions.firstWhere((d)=>d['value']==t,orElse:()=>_deviceTypeOptions[0])['label'] as String;

  @override Widget build(BuildContext context)=>Stack(children:[SingleChildScrollView(padding:const EdgeInsets.symmetric(horizontal:12),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    const SizedBox(height:12),Row(children:[Container(padding:const EdgeInsets.symmetric(horizontal:10,vertical:4),decoration:BoxDecoration(color:NeuTheme.warning,borderRadius:BorderRadius.circular(NeuTheme.radiusFull)),child:const Row(mainAxisSize:MainAxisSize.min,children:[Icon(Icons.device_hub,color:Colors.white,size:14),SizedBox(width:4),Text('子节点',style:TextStyle(fontSize:12,fontWeight:FontWeight.bold,color:Colors.white))])),const SizedBox(width:10),const Text('参数配置',style:TextStyle(fontSize:15,fontWeight:FontWeight.bold,color:NeuTheme.textPrimary)),const Spacer(),if(_hasChanges)TextButton.icon(onPressed:_isLoading?null:_saveConfig,icon:const Icon(Icons.save,size:16,color:NeuTheme.accent),label:const Text('保存',style:TextStyle(color:NeuTheme.accent))),IconButton(onPressed:_isLoading?null:_readConfig,icon:_isLoading?const SizedBox(width:16,height:16,child:CircularProgressIndicator(strokeWidth:2,color:NeuTheme.accent)):const Icon(Icons.refresh,size:20))]),
    const SizedBox(height:10),_buildModbusSection(),const SizedBox(height:10),_buildUartSection(),const SizedBox(height:20),
  ]))]);

  Widget _buildModbusSection()=>Container(decoration:NeuTheme.cardDecoration(),child:Column(children:[
    Padding(padding:const EdgeInsets.symmetric(horizontal:10,vertical:8),child:Row(mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[
      const Text('Modbus 地址预设',style:TextStyle(fontSize:13,fontWeight:FontWeight.bold,color:NeuTheme.textPrimary)),
      GestureDetector(onTap:widget.isConnected?_resetModbusAddresses:null,child:Text('重置默认',style:TextStyle(color:widget.isConnected?NeuTheme.accent:NeuTheme.textMuted,fontSize:11))),
    ])),Container(height:1,color:NeuTheme.bg,margin:const EdgeInsets.symmetric(horizontal:10)),
    Padding(padding:const EdgeInsets.all(10),child:GridView.builder(shrinkWrap:true,physics:const NeverScrollableScrollPhysics(),gridDelegate:const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount:4,crossAxisSpacing:6,mainAxisSpacing:6,childAspectRatio:1.0),itemCount:8,itemBuilder:(c,i)=>_buildModbusCard(i))),
  ]));
  Widget _buildUartSection()=>Column(crossAxisAlignment:CrossAxisAlignment.start,children:[_buildSectionTitle('串口参数'),Container(decoration:NeuTheme.cardDecoration(),child:Column(children:[
    _buildParamRow('波特率',_getBaudRateLabel(),()=>_showBaudRatePicker()),Container(height:1,color:NeuTheme.bg,margin:const EdgeInsets.symmetric(horizontal:10)),
    _buildParamRow('数据位','$_dataBits',()=>_showDataBitsPicker()),Container(height:1,color:NeuTheme.bg,margin:const EdgeInsets.symmetric(horizontal:10)),
    _buildParamRow('停止位','$_stopBits',()=>_showStopBitsPicker()),Container(height:1,color:NeuTheme.bg,margin:const EdgeInsets.symmetric(horizontal:10)),
    _buildParamRow('校验位',_getParityLabel(),()=>_showParityPicker()),
  ]))]);
  Widget _buildSectionTitle(String t)=>Padding(padding:const EdgeInsets.only(bottom:6),child:Text(t,style:const TextStyle(fontSize:13,fontWeight:FontWeight.bold,color:NeuTheme.textPrimary)));
  Widget _buildModbusCard(int i){final l=_getDeviceTypeLabel(_modbusDeviceTypes[i]),r=_modbusDeviceTypes[i]==DtuProtocol.DEV_TYPE_RESERVED;return GestureDetector(onTap:widget.isConnected?()=>_showAddressEditor(i):null,child:Container(decoration:BoxDecoration(color:NeuTheme.card,borderRadius:BorderRadius.circular(NeuTheme.radiusSm),boxShadow:NeuTheme.shadowRaisedSm),child:Column(children:[Container(width:double.infinity,padding:const EdgeInsets.symmetric(vertical:4),decoration:BoxDecoration(color:NeuTheme.bg,borderRadius:const BorderRadius.vertical(top:Radius.circular(7))),child:Text(l,textAlign:TextAlign.center,style:TextStyle(fontSize:9,fontWeight:FontWeight.w500,color:r?NeuTheme.textMuted:NeuTheme.accent),overflow:TextOverflow.ellipsis)),Expanded(child:Center(child:Text('${_modbusAddresses[i]}',style:TextStyle(fontSize:16,fontWeight:FontWeight.bold,color:widget.isConnected?NeuTheme.textPrimary:NeuTheme.textMuted))))])));}
  Widget _buildParamRow(String l,String v,VoidCallback t)=>InkWell(onTap:widget.isConnected&&!_isLoading?t:null,child:Padding(padding:const EdgeInsets.symmetric(horizontal:12,vertical:10),child:Row(mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[Text(l,style:const TextStyle(fontSize:13,fontWeight:FontWeight.w500,color:NeuTheme.textPrimary)),Row(children:[Text(v,style:TextStyle(fontSize:13,color:widget.isConnected?NeuTheme.accent:NeuTheme.textMuted,fontWeight:FontWeight.w600)),Icon(Icons.chevron_right,color:widget.isConnected?NeuTheme.accent:NeuTheme.textMuted,size:16)])])));
  void _resetModbusAddresses(){setState((){_resetModbusConfigToDefault();_hasChanges=true;});_sendModbusConfig();}
  void _resetModbusConfigToDefault(){_modbusAddresses.setAll(0,[1,2,3,4,5,6,7,8]);_modbusDeviceTypes.setAll(0,[5,5,5,5,5,5,5,5]);}
  Future<void> _sendUartConfig() async {if(!widget.isConnected||_isLoading)return;setState(()=>_isLoading=true);try{await _service.writeUartConfig(UartConfig(baudLevel:_baudLevel,parity:_parity,stopBits:_stopBits,dataBits:_dataBits));if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('串口配置已同步'),backgroundColor:NeuTheme.success,duration:Duration(seconds:1)));}catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('串口配置失败:$e'),backgroundColor:NeuTheme.error));}finally{if(mounted)setState(()=>_isLoading=false);}}
  Future<void> _sendModbusConfig() async {if(!widget.isConnected||_isLoading)return;setState(()=>_isLoading=true);try{await _service.writeModbusConfig(ModbusConfig(items:List.generate(8,(i)=>ModbusItem(addr:_modbusAddresses[i],devType:_modbusDeviceTypes[i]))));if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Modbus配置已同步'),backgroundColor:NeuTheme.success,duration:Duration(seconds:1)));}catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Modbus配置失败:$e'),backgroundColor:NeuTheme.error));}finally{if(mounted)setState(()=>_isLoading=false);}}
  void _showBaudRatePicker(){_showOptionsPicker('波特率',_baudRates.map((b)=>b['label']as String).toList(),_getBaudRateLabel(),(s)async{setState((){_baudLevel=_baudRates.firstWhere((b)=>b['label']==s)['value']as int;_hasChanges=true;});await _sendUartConfig();});}
  void _showDataBitsPicker(){_showOptionsPicker('数据位',_dataBitsList,'$_dataBits',(s)async{setState((){_dataBits=int.parse(s);_hasChanges=true;});await _sendUartConfig();});}
  void _showStopBitsPicker(){_showOptionsPicker('停止位',_stopBitsList,'$_stopBits',(s)async{setState((){_stopBits=int.parse(s);_hasChanges=true;});await _sendUartConfig();});}
  void _showParityPicker(){_showOptionsPicker('校验位',_parityList.map((p)=>p['label']as String).toList(),_getParityLabel(),(s)async{setState((){_parity=_parityList.firstWhere((p)=>p['label']==s)['value']as int;_hasChanges=true;});await _sendUartConfig();});}

  void _showOptionsPicker(String t,List<String> o,String cv,Function(String) fn)=>showDialog(context:context,builder:(c)=>AlertDialog(backgroundColor:NeuTheme.bg,shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(NeuTheme.radiusMd)),title:Text('选择 $t',style:const TextStyle(color:NeuTheme.textPrimary,fontSize:15)),content:Column(mainAxisSize:MainAxisSize.min,children:o.map((o)=>ListTile(dense:true,title:Text(o,style:const TextStyle(color:NeuTheme.textPrimary,fontSize:13)),trailing:o==cv?const Icon(Icons.check,color:NeuTheme.accent,size:18):null,onTap:(){fn(o);Navigator.pop(c);})).toList())));

  void _showAddressEditor(int i){
    final ac=TextEditingController(text:_modbusAddresses[i].toString());int st=_modbusDeviceTypes[i];
    showGeneralDialog(context:context,barrierDismissible:true,barrierLabel:'',barrierColor:Colors.black54,transitionDuration:const Duration(milliseconds:200),transitionBuilder:(c,a,s,ch)=>ScaleTransition(scale:CurvedAnimation(parent:a,curve:Curves.easeOutBack),child:FadeTransition(opacity:a,child:ch)),pageBuilder:(c,a,s)=>StatefulBuilder(builder:(c,sd)=>Center(child:Material(color:Colors.transparent,child:Container(margin:const EdgeInsets.symmetric(horizontal:32),padding:const EdgeInsets.all(20),decoration:BoxDecoration(color:NeuTheme.bg,borderRadius:BorderRadius.circular(NeuTheme.radiusLg),boxShadow:NeuTheme.shadowRaisedLg),child:Column(mainAxisSize:MainAxisSize.min,crossAxisAlignment:CrossAxisAlignment.start,children:[
      Row(children:[const Icon(Icons.settings_applications,color:NeuTheme.accent,size:20),const SizedBox(width:8),const Text('Modbus 预设',style:TextStyle(fontSize:18,fontWeight:FontWeight.bold,color:NeuTheme.textPrimary)),const Spacer(),Container(padding:const EdgeInsets.symmetric(horizontal:10,vertical:4),decoration:BoxDecoration(color:NeuTheme.card,borderRadius:BorderRadius.circular(NeuTheme.radiusSm)),child:Text('#${i+1}',style:const TextStyle(fontSize:13,color:NeuTheme.accent,fontWeight:FontWeight.w600)))]),
      const SizedBox(height:20),Container(height:1,color:NeuTheme.card),const SizedBox(height:16),
      const Row(children:[Icon(Icons.category,color:NeuTheme.accent,size:18),SizedBox(width:8),Text('设备类型',style:TextStyle(fontSize:14,fontWeight:FontWeight.bold,color:NeuTheme.textPrimary))]),const SizedBox(height:10),
      Container(decoration:BoxDecoration(color:NeuTheme.card,borderRadius:BorderRadius.circular(NeuTheme.radiusSm)),child:Column(children:_deviceTypeOptions.map((t){final s=st==t['value'];return ListTile(dense:true,title:Text(t['label']as String,style:const TextStyle(fontSize:14,color:NeuTheme.textPrimary)),trailing:s?const Icon(Icons.check,color:NeuTheme.accent):null,onTap:()=>sd(()=>st=t['value']as int));}).toList())),
      const SizedBox(height:16),
      const Row(children:[Icon(Icons.tag,color:NeuTheme.accent,size:18),SizedBox(width:8),Text('Modbus 地址',style:TextStyle(fontSize:14,fontWeight:FontWeight.bold,color:NeuTheme.textPrimary))]),const SizedBox(height:10),
      TextField(controller:ac,keyboardType:TextInputType.number,textAlign:TextAlign.center,style:const TextStyle(fontSize:24,fontWeight:FontWeight.bold,color:NeuTheme.accent),decoration:const InputDecoration(hintText:'1-255',border:InputBorder.none,contentPadding:EdgeInsets.symmetric(horizontal:16,vertical:16))),
      const SizedBox(height:20),
      Row(children:[Expanded(child:_DialogButton(label:'取消',isPrimary:false,onPressed:()=>Navigator.pop(c))),const SizedBox(width:12),Expanded(child:_DialogButton(label:'保存',isPrimary:true,onPressed:()async{final v=int.tryParse(ac.text);if(v!=null&&v>=1&&v<=255){setState((){_modbusAddresses[i]=v;_modbusDeviceTypes[i]=st;_hasChanges=true;});}Navigator.pop(c);await _sendModbusConfig();}))]),
    ]))))));
  }
}

class _ExpandableDropdown extends StatefulWidget {final String selectedType;final List<String> options;final Function(String) onTypeSelected;const _ExpandableDropdown({required this.selectedType,required this.options,required this.onTypeSelected});@override State<_ExpandableDropdown> createState()=>_ExpandableDropdownState();}
class _ExpandableDropdownState extends State<_ExpandableDropdown> {bool _isExpanded=false;@override Widget build(BuildContext c)=>Column(children:[GestureDetector(onTap:()=>setState(()=>_isExpanded=!_isExpanded),child:Container(width:double.infinity,decoration:BoxDecoration(color:NeuTheme.card,borderRadius:BorderRadius.circular(NeuTheme.radiusSm)),padding:const EdgeInsets.symmetric(horizontal:12,vertical:14),child:Row(mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[Padding(padding:const EdgeInsets.only(left:4),child:Text(widget.selectedType,style:const TextStyle(fontSize:14,color:NeuTheme.accent,fontWeight:FontWeight.w500))),AnimatedRotation(turns:_isExpanded?0.5:0,duration:const Duration(milliseconds:200),child:const Icon(Icons.expand_more,color:NeuTheme.accent,size:20))]))),if(_isExpanded)Container(margin:const EdgeInsets.only(top:6),padding:const EdgeInsets.all(8),decoration:BoxDecoration(color:NeuTheme.card,borderRadius:BorderRadius.circular(NeuTheme.radiusSm)),child:Column(children:widget.options.map((t){final s=t==widget.selectedType;return GestureDetector(onTap:(){widget.onTypeSelected(t);setState(()=>_isExpanded=false);},child:Container(width:double.infinity,padding:const EdgeInsets.symmetric(vertical:10,horizontal:8),decoration:BoxDecoration(color:s?NeuTheme.accentLight:Colors.transparent,borderRadius:BorderRadius.circular(4)),child:Row(children:[Text(t,style:TextStyle(fontSize:13,color:s?NeuTheme.accent:NeuTheme.textPrimary,fontWeight:s?FontWeight.w600:FontWeight.normal)),const Spacer(),if(s)const Icon(Icons.check,color:NeuTheme.accent,size:16)])));}).toList()))]);}

class _DialogButton extends StatefulWidget {final String label;final bool isPrimary;final VoidCallback onPressed;const _DialogButton({required this.label,required this.isPrimary,required this.onPressed});@override State<_DialogButton> createState()=>_DialogButtonState();}
class _DialogButtonState extends State<_DialogButton> {bool _p=false;@override Widget build(BuildContext c)=>GestureDetector(onTapDown:(_)=>setState(()=>_p=true),onTapUp:(_){setState(()=>_p=false);widget.onPressed();},onTapCancel:()=>setState(()=>_p=false),child:AnimatedContainer(duration:const Duration(milliseconds:100),padding:const EdgeInsets.symmetric(vertical:14),decoration:BoxDecoration(color:widget.isPrimary?(_p?NeuTheme.accentHover:NeuTheme.accent):(_p?NeuTheme.card:NeuTheme.bg),borderRadius:BorderRadius.circular(NeuTheme.radiusMd),border:widget.isPrimary?null:Border.all(color:NeuTheme.accent,width:1.5),boxShadow:widget.isPrimary?[BoxShadow(color:NeuTheme.accent.withValues(alpha:0.3),blurRadius:8,offset:const Offset(0,4))]:NeuTheme.shadowRaisedSm),child:Text(widget.label,textAlign:TextAlign.center,style:TextStyle(fontSize:15,fontWeight:FontWeight.w600,color:widget.isPrimary?Colors.white:NeuTheme.accent))));}
