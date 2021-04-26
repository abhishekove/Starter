import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/dbms/circular.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'package:url_launcher/url_launcher.dart';

class BottomCards extends StatefulWidget {
  Circular circular;
  bool dataFromDatabase;
  BottomCards({this.circular, this.dataFromDatabase});
  @override
  _BottomCardsState createState() => _BottomCardsState();
}

class _BottomCardsState extends State<BottomCards>{
  bool expand=false;
  Widget expander(){
    return AnimatedCrossFade(firstChild: Linkify(
      onOpen: (link) async {
        if (await canLaunch(link.url)) {
          await launch(link.url);
        } else {
          throw "Could not launch $link";
        }
      },
      text: widget.circular.content.toString(),
      style: GoogleFonts.rajdhani(
          textStyle: TextStyle(fontSize: 16, height: 1.25,color: Colors.black,fontWeight: FontWeight.w500)),
      linkStyle: TextStyle(
        color: Colors.blue,
      ),
    ), secondChild: Linkify(
      onOpen: (link) async {
        if (await canLaunch(link.url)) {
          await launch(link.url);
        } else {
          throw "Could not launch $link";
        }
      },
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      text: widget.circular.content.toString(),
      style: GoogleFonts.rajdhani(
          textStyle: TextStyle(fontSize: 16, height: 1.25,color: Colors.black,fontWeight: FontWeight.w500)),
      linkStyle: TextStyle(
        color: Colors.blue,
      ),
    ), crossFadeState: expand?CrossFadeState.showFirst:CrossFadeState.showSecond, duration: const Duration(milliseconds: 250));
  }

  @override
  Widget build(BuildContext context) {
    String displayDate = "";
    String val = widget.circular.date.toLocal().toString();
    for (int i = 0; i < val.length - 7; i++) displayDate += val[i];

    List<Widget> chipList=[];
    List<Widget> buttonList=[];
    for(int i=0;i<widget.circular.channels.length;i++){
      chipList.add(GestureDetector(
        onTap: (){
          // Navigator.push(context, MaterialPageRoute(builder: (context)=>ChannelScreen(docId: widget.circular.channels[i].toString(),channelDescription: "",)));
        },
        child: Chip(
          label: Text(widget.circular.channels[i].toString()),
        ),
      ));
    }
    for(int i=0;i<widget.circular.files.length;i++){
      buttonList.add(FlatButton(onPressed: () async {
        if (await canLaunch(widget.circular.files[i])) {
          await launch(widget.circular.files[i]);
        } else {
          throw "Could not launch ${widget.circular.files[i]}";
        }
      }, child: Text("File "+(i+1).toString(),),));
    }

    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: Card(
        elevation: 0,
        child: FlatButton(
          onPressed: (){
            setState(() {
              expand=!expand;
            });
          },
          child: InkWell(
            splashColor: Colors.blue.withAlpha(30),
            onTap: () {},
            child: Container(
              child: Padding(
                padding: EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: <Widget>[
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: 10.0,),
                            Container(
                              width: MediaQuery.of(context).size.width-150,
                              child: Text(widget.circular.title,style:  GoogleFonts.rajdhani(
                                  textStyle: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w600,
                                    height: 0.9,
                                  )),),
                            ),
                            Text(
                              widget.circular.author.toString(),
                              style: GoogleFonts.rajdhani(
                                  textStyle: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      height: 0.9)),
                            ),
                            Text(
                              displayDate,
                              style: GoogleFonts.rajdhani(
                                  textStyle: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w400,
                                      height: 0.8)),
                            )
                          ],
                        ),
                        Spacer(),
                        new ButtonBar(
                          children: <Widget>[
                            new IconButton(
                                color: Colors.black.withOpacity(0.75),
                                padding: EdgeInsets.symmetric(vertical: 0, horizontal: 10),
                                constraints: BoxConstraints(),
                                icon: Icon((widget.dataFromDatabase
                                    ? Icons.delete
                                    : Icons.bookmark_border)),
                                onPressed: () {
                                  var box = Hive.box('myBox');
                                  List postList = box.get('postList');
                                  if (widget.dataFromDatabase) {
                                    box.delete(widget.circular.id.trim());
                                    print(widget.circular.id.trim());
                                    postList.removeWhere((element) =>
                                    element.id.toString().trim() ==
                                        widget.circular.id.trim());
                                  } else {
                                    print(widget.circular.id.trim());
                                    box.put(widget.circular.id.trim(), true);
                                    postList.add(widget.circular);
                                  }
                                  box.put('postList', postList);
                                  setState(() {
                                    widget.dataFromDatabase = !widget.dataFromDatabase;
                                  });
                                }),
                          ],
                        )
                      ],
                    ),
                    if (widget.circular.imgUrl=="") SizedBox(height: 10.0,) else Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: CachedNetworkImage(imageUrl: widget.circular.imgUrl,progressIndicatorBuilder: (context, url, downloadProgress) =>
                          CircularProgressIndicator(value: downloadProgress.progress),
                        errorWidget: (context, url, error) => Icon(Icons.error),),
                    ),
                    GestureDetector(child: expander(),onTap: (){
                      setState(() {
                        expand=!expand;
                      });
                    },),
                    Row(
                      children: [
                        ButtonBar(
                          alignment: MainAxisAlignment.spaceBetween,
                          children: buttonList,
                        ),
                        Spacer(),
                        ButtonBar(
                          alignment: MainAxisAlignment.spaceBetween,
                          children: chipList,
                        )
                      ],
                    )
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}