import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

const navy = Color(0xFF101A2C);
const gold = Color(0xFFD4AF37);

void main() => runApp(const MirasMelkApp());

class MirasMelkApp extends StatefulWidget {
  const MirasMelkApp({super.key});
  @override State<MirasMelkApp> createState() => _MirasMelkAppState();
}
class _MirasMelkAppState extends State<MirasMelkApp> {
  bool dark = true;
  @override Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'میراث ملک',
    theme: ThemeData(useMaterial3: true, colorScheme: ColorScheme.fromSeed(seedColor: gold)),
    darkTheme: ThemeData(useMaterial3: true, colorScheme: ColorScheme.fromSeed(seedColor: gold, brightness: Brightness.dark)),
    themeMode: dark ? ThemeMode.dark : ThemeMode.light,
    home: LoginPage(onTheme: (v) => setState(() => dark = v)),
  );
}

class Store {
  static Future<List<Map<String,dynamic>>> files() async {
    final p = await SharedPreferences.getInstance();
    return (jsonDecode(p.getString('files') ?? '[]') as List).map((e) => Map<String,dynamic>.from(e)).toList();
  }
  static Future<void> saveFiles(List<Map<String,dynamic>> x) async {
    final p = await SharedPreferences.getInstance(); await p.setString('files', jsonEncode(x));
  }
  static Future<List<String>> customers() async { final p=await SharedPreferences.getInstance(); return p.getStringList('customers') ?? []; }
  static Future<void> saveCustomers(List<String> x) async { final p=await SharedPreferences.getInstance(); await p.setStringList('customers', x); }
  static Future<String> get(String k) async { final p=await SharedPreferences.getInstance(); return p.getString(k) ?? ''; }
  static Future<void> set(String k,String v) async { final p=await SharedPreferences.getInstance(); await p.setString(k,v); }
}

class LoginPage extends StatefulWidget {
  final ValueChanged<bool> onTheme;
  const LoginPage({super.key,required this.onTheme});
  @override State<LoginPage> createState()=>_LoginPageState();
}
class _LoginPageState extends State<LoginPage> {
  final user=TextEditingController(), pass=TextEditingController(); bool hide=true;
  Future<void> login() async {
    final saved=await Store.get('admin_password');
    final ok=(user.text=='admin' && pass.text==(saved.isEmpty?'1234':saved)) || (user.text=='modir' && pass.text=='1234');
    if(ok && mounted) Navigator.pushReplacement(context,MaterialPageRoute(builder:(_)=>HomePage(onTheme:widget.onTheme)));
    else if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('نام کاربری یا رمز عبور اشتباه است')));
  }
  @override Widget build(BuildContext c)=>Directionality(textDirection:TextDirection.rtl,child:Scaffold(backgroundColor:navy,body:Center(child:SingleChildScrollView(padding:const EdgeInsets.all(22),child:Card(child:Padding(padding:const EdgeInsets.all(24),child:Column(children:[Container(width:92,height:92,decoration:BoxDecoration(color:gold,borderRadius:BorderRadius.circular(28)),child:const Icon(Icons.apartment,size:55,color:navy)),const SizedBox(height:14),const Text('میراث ملک',style:TextStyle(fontSize:32,fontWeight:FontWeight.w900)),const Text('سیستم مدیریت هوشمند دپارتمان املاک'),const SizedBox(height:25),TextField(controller:user,decoration:const InputDecoration(labelText:'نام کاربری',prefixIcon:Icon(Icons.person))),const SizedBox(height:12),TextField(controller:pass,obscureText:hide,decoration:InputDecoration(labelText:'رمز عبور',prefixIcon:const Icon(Icons.lock),suffixIcon:IconButton(onPressed:()=>setState(()=>hide=!hide),icon:Icon(hide?Icons.visibility:Icons.visibility_off)))),const SizedBox(height:18),SizedBox(width:double.infinity,height:52,child:FilledButton(onPressed:login,child:const Text('ورود به سامانه'))),const SizedBox(height:10),const Text('مدیریت مهندس مجتبی صفری • مدیر فروش خانم طهماسبی پور',textAlign:TextAlign.center,style:TextStyle(fontSize:12))]))))));
}

class HomePage extends StatefulWidget {
  final ValueChanged<bool> onTheme; const HomePage({super.key,required this.onTheme});
  @override State<HomePage> createState()=>_HomePageState();
}
class _HomePageState extends State<HomePage> {
  int tab=0; List<Map<String,dynamic>> files=[]; List<String> customers=[];
  @override void initState(){super.initState(); refresh();}
  Future<void> refresh() async { files=await Store.files(); customers=await Store.customers(); if(mounted)setState((){}); }
  @override Widget build(BuildContext c){
    final pages=[Dashboard(files:files,customers:customers,onRefresh:refresh),FilesPage(files:files,onRefresh:refresh),CustomersPage(customers:customers,onRefresh:refresh),MessagesPage(customers:customers),const CommissionPage(),SettingsPage(onTheme:widget.onTheme)];
    return Directionality(textDirection:TextDirection.rtl,child:Scaffold(appBar:AppBar(title:const Text('میراث ملک'),actions:[IconButton(onPressed:refresh,icon:const Icon(Icons.refresh))]),body:pages[tab],bottomNavigationBar:NavigationBar(selectedIndex:tab,onDestinationSelected:(i)=>setState(()=>tab=i),destinations:const[NavigationDestination(icon:Icon(Icons.dashboard),label:'خانه'),NavigationDestination(icon:Icon(Icons.home_work),label:'فایل‌ها'),NavigationDestination(icon:Icon(Icons.people),label:'مشتریان'),NavigationDestination(icon:Icon(Icons.message),label:'پیام'),NavigationDestination(icon:Icon(Icons.calculate),label:'کمیسیون'),NavigationDestination(icon:Icon(Icons.settings),label:'تنظیمات')]));
  }
}

class Dashboard extends StatelessWidget {
  final List<Map<String,dynamic>> files; final List<String> customers; final VoidCallback onRefresh;
  const Dashboard({super.key,required this.files,required this.customers,required this.onRefresh});
  @override Widget build(BuildContext c)=>ListView(padding:const EdgeInsets.all(16),children:[Container(padding:const EdgeInsets.all(20),decoration:BoxDecoration(color:navy,borderRadius:BorderRadius.circular(22)),child:const Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('دپارتمان میراث ملک',style:TextStyle(color:gold,fontSize:28,fontWeight:FontWeight.w900)),SizedBox(height:6),Text('مدیریت مهندس مجتبی صفری',style:TextStyle(color:Colors.white,fontSize:16)),Text('مدیر فروش خانم طهماسبی پور',style:TextStyle(color:Colors.white70))])),const SizedBox(height:15),Row(children:[_stat('فایل',files.length,Icons.home_work),_stat('مشتری',customers.length,Icons.people)]),const SizedBox(height:15),FilledButton.icon(onPressed:()=>Navigator.push(c,MaterialPageRoute(builder:(_)=>FileForm(onSaved:onRefresh))),icon:const Icon(Icons.add),label:const Text('ثبت فایل جدید')),const SizedBox(height:10),const Card(child:Padding(padding:EdgeInsets.all(14),child:Text('لینک دیوار را در ثبت فایل وارد کن؛ اطلاعات عمومی آگهی خودکار وارد می‌شود. شماره خصوصی مالک فقط از مسیر رسمی دیوار و با رضایت/مجوز او قابل دریافت است.')))]);
  static Widget _stat(String t,int n,IconData i)=>Expanded(child:Card(child:Padding(padding:const EdgeInsets.all(15),child:Row(children:[Icon(i,color:gold),const SizedBox(width:10),Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('$n',style:const TextStyle(fontSize:25,fontWeight:FontWeight.w900)),Text(t)])]))));
}

class FilesPage extends StatefulWidget { final List<Map<String,dynamic>> files; final VoidCallback onRefresh; const FilesPage({super.key,required this.files,required this.onRefresh}); @override State<FilesPage> createState()=>_FilesPageState(); }
class _FilesPageState extends State<FilesPage> { String q=''; @override Widget build(BuildContext c){ final list=widget.files.where((x)=>('${x['title']} ${x['code']} ${x['address']} ${x['ownerPhone']}'.toLowerCase()).contains(q.toLowerCase())).toList(); return Column(children:[Padding(padding:const EdgeInsets.all(12),child:TextField(onChanged:(v)=>setState(()=>q=v),decoration:const InputDecoration(prefixIcon:Icon(Icons.search),labelText:'جستجوی فایل'))),Expanded(child:list.isEmpty?const Center(child:Text('هنوز فایلی ثبت نشده')):ListView.builder(itemCount:list.length,itemBuilder:(c,i){final x=list[i];return Card(margin:const EdgeInsets.symmetric(horizontal:12,vertical:5),child:ListTile(title:Text(x['title']??'ملک',style:const TextStyle(fontWeight:FontWeight.bold)),subtitle:Text('کد ${x['code']} • ${x['type']} • ${x['price']}\nمالک: ${x['ownerName']} • ${x['ownerPhone']}',maxLines:2),trailing:const Icon(Icons.chevron_left),onTap:()=>Navigator.push(c,MaterialPageRoute(builder:(_)=>FileDetails(file:x,onRefresh:widget.onRefresh))));}))]); } }

class FileDetails extends StatelessWidget { final Map<String,dynamic> file; final VoidCallback onRefresh; const FileDetails({super.key,required this.file,required this.onRefresh}); @override Widget build(BuildContext c)=>Scaffold(appBar:AppBar(title:Text(file['title']??'جزئیات فایل')),body:ListView(padding:const EdgeInsets.all(16),children:[for(final e in {'کد':'code','نوع ملک':'type','نوع معامله':'deal','متراژ':'area','قیمت':'price','آدرس':'address','نام مالک':'ownerName','شماره مالک':'ownerPhone','توضیحات':'description'}.entries) Card(child:Padding(padding:const EdgeInsets.all(12),child:Text('${e.key}: ${file[e.value]??''}'))),if((file['divarLink']??'').toString().isNotEmpty)FilledButton.icon(onPressed:()=>launchUrl(Uri.parse(file['divarLink'])),icon:const Icon(Icons.open_in_new),label:const Text('باز کردن لینک دیوار')),if((file['ownerPhone']??'').toString().isNotEmpty)OutlinedButton.icon(onPressed:()=>launchUrl(Uri(scheme:'tel',path:file['ownerPhone'])),icon:const Icon(Icons.call),label:const Text('تماس با مالک')),if((file['images'] is List && (file['images'] as List).isNotEmpty))...[(file['images'] as List).map((u)=>Padding(padding:const EdgeInsets.only(bottom:8),child:Image.network('$u',height:170,fit:BoxFit.cover,errorBuilder:(_,__,___)=>const SizedBox.shrink()))).toList()],FilledButton(onPressed:()=>Navigator.push(c,MaterialPageRoute(builder:(_)=>FileForm(existing:file,onSaved:onRefresh))),child:const Text('ویرایش فایل'))])); }
}

class FileForm extends StatefulWidget { final Map<String,dynamic>? existing; final VoidCallback onSaved; const FileForm({super.key,this.existing,required this.onSaved}); @override State<FileForm> createState()=>_FileFormState(); }
class _FileFormState extends State<FileForm> {
  late final TextEditingController title,type,deal,area,price,address,owner,phone,desc,link,apiKey,token;
  bool loading=false; String msg='';
  @override void initState(){super.initState();final x=widget.existing??{};title=TextEditingController(text:'${x['title']??''}');type=TextEditingController(text:'${x['type']??'آپارتمان'}');deal=TextEditingController(text:'${x['deal']??'فروش'}');area=TextEditingController(text:'${x['area']??''}');price=TextEditingController(text:'${x['price']??''}');address=TextEditingController(text:'${x['address']??''}');owner=TextEditingController(text:'${x['ownerName']??''}');phone=TextEditingController(text:'${x['ownerPhone']??''}');desc=TextEditingController(text:'${x['description']??''}');link=TextEditingController(text:'${x['divarLink']??''}');apiKey=TextEditingController();token=TextEditingController();}
  String? divarToken(){ final patterns=[RegExp(r'divar\.ir/v/([A-Za-z0-9_-]{6,20})'),RegExp(r'divar\.ir/[^/]+/[^/]+/([A-Za-z0-9_-]{6,20})')]; for(final r in patterns){final m=r.firstMatch(link.text);if(m!=null)return m.group(1);} return null; }
  Future<void> importDivar() async { final t=divarToken(); if(t==null){setState(()=>msg='لینک دیوار معتبر نیست');return;} if(apiKey.text.trim().isEmpty){setState(()=>msg='API Key رسمی دیوار را وارد کن');return;} setState(()=>loading=true); try { final r=await http.get(Uri.parse('https://open-api.divar.ir/v1/open-platform/finder/post/$t'),headers:{'x-api-key':apiKey.text.trim()}); final j=jsonDecode(r.body); if(r.statusCode<200||r.statusCode>=300)throw Exception(j['message']??'خطای API'); final d=Map<String,dynamic>.from(j['data']??{}); final p=d['price']; final imgs=(d['images'] is List)?List<String>.from((d['images'] as List).map((e)=>'$e')):<String>[]; setState((){title.text='${d['title']??d['prefilled_title']??''}';area.text='${d['size']??d['area']??''}';price.text=p is Map?'${p['value']??''}':'${p??''}';address.text='${j['address']??j['district']??address.text}';desc.text='${d['description']??''}';msg='اطلاعات عمومی آگهی وارد شد. شماره مالک خصوصی از GET_POST برنمی‌گردد.';}); await Store.set('last_divar_images',jsonEncode(imgs)); } catch(e){setState(()=>msg='خطا در دریافت آگهی: $e');} finally {if(mounted)setState(()=>loading=false);} }
  Future<void> authorizedPhone() async { if(apiKey.text.trim().isEmpty||token.text.trim().isEmpty){setState(()=>msg='API Key و Access Token رسمی لازم است');return;} try{final r=await http.post(Uri.parse('https://open-api.divar.ir/v1/open-platform/users'),headers:{'x-api-key':apiKey.text.trim(),'Authorization':'Bearer ${token.text.trim()}','Content-Type':'application/json'},body:'{}');final j=jsonDecode(r.body);if(r.statusCode>=200&&r.statusCode<300&&j['phone_numbers'] is List&&(j['phone_numbers'] as List).isNotEmpty){setState(()=>phone.text='${j['phone_numbers'][0]}');}else{setState(()=>msg='شماره با این مجوز برنگشت؛ مالک باید USER_PHONE را به برنامه رسمی شما داده باشد.');}}catch(e){setState(()=>msg='خطا در دریافت شماره مجاز: $e');} }
  Future<void> save() async { final all=await Store.files(); final code=widget.existing?['code']??'MM-${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}':'MM-${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}'; final imgs=await Store.get('last_divar_images'); final x={'code':code,'title':title.text,'type':type.text,'deal':deal.text,'area':area.text,'price':price.text,'address':address.text,'ownerName':owner.text,'ownerPhone':phone.text,'description':desc.text,'divarLink':link.text,'images':imgs.isEmpty?[]:jsonDecode(imgs),'updated':DateFormat('yyyy/MM/dd HH:mm').format(DateTime.now())}; final i=all.indexWhere((e)=>e['code']==code);if(i>=0)all[i]=x;else all.add(x);await Store.saveFiles(all);if(phone.text.trim().isNotEmpty){final cs=await Store.customers();if(!cs.contains(phone.text.trim())){cs.add(phone.text.trim());await Store.saveCustomers(cs);}}widget.onSaved();if(mounted)Navigator.pop(context); }
  @override Widget build(BuildContext c)=>Scaffold(appBar:AppBar(title:Text(widget.existing==null?'ثبت فایل جدید':'ویرایش فایل')),body:ListView(padding:const EdgeInsets.all(16),children:[_f(title,'عنوان فایل'),_f(type,'نوع ملک'),_f(deal,'نوع معامله'),_f(area,'متراژ'),_f(price,'قیمت'),_f(address,'آدرس'),_f(owner,'نام مالک'),_f(phone,'شماره مالک',keyboard:TextInputType.phone),_f(link,'لینک آگهی دیوار'),Card(child:Padding(padding:const EdgeInsets.all(12),child:Column(children:[const Align(alignment:Alignment.centerRight,child:Text('اتصال رسمی دیوار',style:TextStyle(fontWeight:FontWeight.bold))),_f(apiKey,'API Key دیوار',obscure:true),_f(token,'Access Token رسمی',obscure:true),Row(children:[Expanded(child:FilledButton.icon(onPressed:loading?null:importDivar,icon:const Icon(Icons.download),label:Text(loading?'در حال دریافت...':'ورود خودکار مشخصات'))),const SizedBox(width:8),IconButton(onPressed:authorizedPhone,icon:const Icon(Icons.phone))]),if(msg.isNotEmpty)Padding(padding:const EdgeInsets.only(top:8),child:Text(msg))]))),_f(desc,'توضیحات',multi:true),const SizedBox(height:8),FilledButton.icon(onPressed:save,icon:const Icon(Icons.save),label:const Text('ثبت و ذخیره فایل'))]));
  Widget _f(TextEditingController x,String label,{bool multi=false,TextInputType? keyboard,bool obscure=false})=>Padding(padding:const EdgeInsets.only(bottom:10),child:TextField(controller:x,maxLines:multi?5:1,obscureText:obscure,keyboardType:keyboard,decoration:InputDecoration(labelText:label,border:const OutlineInputBorder())));
}

class CustomersPage extends StatefulWidget { final List<String> customers; final VoidCallback onRefresh; const CustomersPage({super.key,required this.customers,required this.onRefresh}); @override State<CustomersPage> createState()=>_CustomersPageState(); }
class _CustomersPageState extends State<CustomersPage> { final c=TextEditingController(); @override Widget build(BuildContext x)=>Column(children:[Padding(padding:const EdgeInsets.all(12),child:Row(children:[Expanded(child:TextField(controller:c,keyboardType:TextInputType.phone,decoration:const InputDecoration(labelText:'شماره مشتری'))),IconButton(onPressed:()async{final n=c.text.trim();if(n.isEmpty)return;final a=await Store.customers();if(!a.contains(n)){a.add(n);await Store.saveCustomers(a);}c.clear();widget.onRefresh();setState((){});},icon:const Icon(Icons.add_circle))])),Expanded(child:ListView(children:widget.customers.map((n)=>ListTile(leading:const Icon(Icons.phone),title:Text(n),trailing:Wrap(children:[IconButton(onPressed:()=>launchUrl(Uri(scheme:'tel',path:n)),icon:const Icon(Icons.call)),IconButton(onPressed:()=>launchUrl(Uri(scheme:'sms',path:n,queryParameters:{'body':'سلام، از دپارتمان میراث ملک پیام می‌دهیم.'})),icon:const Icon(Icons.sms))]))).toList()))]); }

class MessagesPage extends StatelessWidget { final List<String> customers; const MessagesPage({super.key,required this.customers}); @override Widget build(BuildContext c)=>ListView(padding:const EdgeInsets.all(16),children:[const Text('پیام به مشتریان',style:TextStyle(fontSize:22,fontWeight:FontWeight.w900)),const SizedBox(height:10),...customers.map((n)=>Card(child:ListTile(title:Text(n),subtitle:const Text('سلام، از دپارتمان میراث ملک پیام می‌دهیم.'),trailing:IconButton(onPressed:()=>launchUrl(Uri(scheme:'sms',path:n,queryParameters:{'body':'سلام، از دپارتمان میراث ملک پیام می‌دهیم.'})),icon:const Icon(Icons.send))))),const Card(child:Padding(padding:EdgeInsets.all(14),child:Text('برای چت آنلاین واقعی بین مشاورین، نسخه ابری با حساب کاربری و سرور مشترک لازم است؛ این نسخه ارسال پیامک مشتری را فعال کرده است.'))]); }

class CommissionPage extends StatefulWidget { const CommissionPage({super.key}); @override State<CommissionPage> createState()=>_CommissionPageState(); }
class _CommissionPageState extends State<CommissionPage>{ final amount=TextEditingController(); double percent=.5,vat=10; @override Widget build(BuildContext c){final a=double.tryParse(amount.text.replaceAll(',',''))??0;final base=a*percent/100;final tax=base*vat/100;return ListView(padding:const EdgeInsets.all(16),children:[const Text('محاسبه کمیسیون',style:TextStyle(fontSize:22,fontWeight:FontWeight.w900)),const SizedBox(height:15),TextField(controller:amount,onChanged:(_)=>setState((){}),keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'مبلغ معامله',border:OutlineInputBorder())),const SizedBox(height:12),DropdownButtonFormField<double>(value:percent,items:const[.25,.5,1].map((v)=>DropdownMenuItem(value:v,child:Text('$v درصد'))).toList(),onChanged:(v)=>setState(()=>percent=v??.5),decoration:const InputDecoration(labelText:'درصد کمیسیون')),const SizedBox(height:12),DropdownButtonFormField<double>(value:vat,items:const[0,10].map((v)=>DropdownMenuItem(value:v,child:Text('$v درصد مالیات'))).toList(),onChanged:(v)=>setState(()=>vat=v??10),decoration:const InputDecoration(labelText:'مالیات ارزش افزوده')),const SizedBox(height:20),Card(child:Padding(padding:const EdgeInsets.all(18),child:Column(children:[Text('کمیسیون پایه: ${base.toStringAsFixed(0)}'),Text('مالیات: ${tax.toStringAsFixed(0)}'),const Divider(),Text('مبلغ نهایی: ${(base+tax).toStringAsFixed(0)}',style:const TextStyle(fontSize:22,fontWeight:FontWeight.w900))]))) ]);}}

class SettingsPage extends StatefulWidget { final ValueChanged<bool> onTheme; const SettingsPage({super.key,required this.onTheme}); @override State<SettingsPage> createState()=>_SettingsPageState(); }
class _SettingsPageState extends State<SettingsPage>{bool dark=true;final pass=TextEditingController();@override Widget build(BuildContext c)=>ListView(padding:const EdgeInsets.all(16),children:[SwitchListTile(title:const Text('حالت تیره'),value:dark,onChanged:(v){setState(()=>dark=v);widget.onTheme(v);}),const Divider(),const ListTile(title:Text('مدیریت'),subtitle:Text('مدیریت مهندس مجتبی صفری • مدیر فروش خانم طهماسبی پور')),TextField(controller:pass,obscureText:true,decoration:const InputDecoration(labelText:'رمز جدید مدیر')),FilledButton(onPressed:()async{if(pass.text.length<4)return;await Store.set('admin_password',pass.text);pass.clear();if(c.mounted)ScaffoldMessenger.of(c).showSnackBar(const SnackBar(content:Text('رمز ذخیره شد')));},child:const Text('تغییر رمز')),const SizedBox(height:12),const Card(child:Padding(padding:EdgeInsets.all(14),child:Text('دیوار: GET_POST اطلاعات عمومی آگهی را می‌دهد. برای شماره تلفن خصوصی، دیوار USER_PHONE و رضایت صاحب حساب لازم دارد. API Key و Access Token را فقط در دستگاه/سرور امن خود نگه دارید.')))]);}
