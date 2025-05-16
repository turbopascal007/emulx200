
unit subs3;

interface

uses crt,dos,mdosio,
     gentypes,configrt,modem,statret,gensubs,subs1,windows,subs2,textret,
     mailret,userret,flags,mainr1,ansiedit,lineedit,chatstuf,
     mainr2,overret1,protocol,mainmenu;

type
   signature_type = longint;
const
   local_file_header_signature = $04034b50;
type
   local_file_header = record
      version_needed_to_extract:    word;
      general_purpose_bit_flag:     word;
      compression_method:           word;
      last_mod_file_time:           word;
      last_mod_file_date:           word;
      crc32:                        longint;
      compressed_size:              longint;
      uncompressed_size:            longint;
      filename_length:              word;
      extra_field_length:           word;
   end;
const
   central_file_header_signature = $02014b50;
type
   central_directory_file_header = record
      version_made_by:                 word;
      version_needed_to_extract:       word;
      general_purpose_bit_flag:        word;
      compression_method:              word;
      last_mod_file_time:              word;
      last_mod_file_date:              word;
      crc32:                           longint;
      compressed_size:                 longint;
      uncompressed_size:               longint;
      filename_length:                 word;
      extra_field_length:              word;
      file_comment_length:             word;
      disk_number_start:               word;
      internal_file_attributes:        word;
      external_file_attributes:        longint;
      relative_offset_local_header:    longint;
   end;
const
   end_central_dir_signature = $06054b50;
type
   end_central_dir_record = record
      number_this_disk:                         word;
      number_disk_with_start_central_directory: word;
      total_entries_central_dir_on_this_disk:   word;
      total_entries_central_dir:                word;
      size_central_directory:                   longint;
      offset_start_central_directory:           longint;
      zipfile_comment_length:                   word;
   end;
const
   compression_methods: array[0..6] of string[8]=
      (' Stored ',' Shrunk ','Reduce-1','Reduce-2','Reduce-3','Reduce-4','?');
var
   zipfd:   dos_handle;
   zipfn:   dos_filename;
type
   string8 = string[8];

procedure get_string (len:word; var s:string);
procedure itoa2 (i:integer; var sp);
function format_date (date:word):string8;
function format_time (time:word):string8;
procedure process_local_file_header;
procedure process_central_file_header;
procedure process_end_central_dir;
procedure process_headers;
procedure list_zip (name:dos_filename);
procedure arcview (fname:lstr);
procedure pakview (filename:lstr);
procedure zipview (fn:lstr);

implementation

(* ---------------------------------------------------------- *)
procedure get_string(len: word; var s: string);
var
   n: word;
begin
   if len > 255 then
      len := 255;
   n := dos_read(zipfd,s[1],len);
   s[0] := chr(len);
end;

(* ---------------------------------------------------------- *)
procedure itoa2(i: integer; var sp);
var
   s: array[1..2] of char absolute sp;
begin
   s[1] := chr( (i div 10) + ord('0'));
   s[2] := chr( (i mod 10) + ord('0'));
end;

function format_date(date: word): string8;
const
   s:       string8 = 'mm-dd-yy';
begin
   itoa2(((date shr 9) and 127)+80, s[7]);
   itoa2( (date shr 5) and 15,  s[1]);
   itoa2( (date      ) and 31,  s[4]);
   format_date := s;
end;

function format_time(time: word): string8;
const
   s:       string8 = 'hh:mm:ss';
begin
   itoa2( (time shr 11) and 31, s[1]);
   itoa2( (time shr  5) and 63, s[4]);
   itoa2( (time shl  1) and 63, s[7]);
   format_time := s;
end;

(* ---------------------------------------------------------- *)
procedure process_local_file_header;
var
   n:             word;
   rec:           local_file_header;
   filename:      string;
   extra:         string;

begin
   n := dos_read(zipfd,rec,sizeof(rec));
   get_string(rec.filename_length,filename);
   get_string(rec.extra_field_length,extra);
   dos_lseek(zipfd,rec.compressed_size,seek_cur);
end;

(* ---------------------------------------------------------- *)
procedure process_central_file_header;
var
   n:             word;
   rec:           central_directory_file_header;
   filename:      string;
   extra:         string;
   comment:       string;

begin
   n := dos_read(zipfd,rec,sizeof(rec));
   get_string(rec.filename_length,filename);
   get_string(rec.extra_field_length,extra);
   get_string(rec.file_comment_length,comment);

   write(rec.uncompressed_size:7,'  ',
           compression_methods[rec.compression_method]:8,' ',
           rec.compressed_size:7,'   ',
           format_date(rec.last_mod_file_date),'  ',
           format_time(rec.last_mod_file_time));

   if (rec.internal_file_attributes and 1) <> 0 then
      write('   Ascii  ')
   else
      write('  Binary  ');

   writeln(filename);

(**************
   writeln;
   writeln('central file header');
   writeln('   filename = ',filename);
   writeln('   extra = ',extra);
   writeln('   file comment = ',comment);
   writeln('   version_made_by = ',rec.version_made_by);
   writeln('   version_needed_to_extract = ',rec.version_needed_to_extract);
   writeln('   general_purpose_bit_flag = ',rec.general_purpose_bit_flag);
   writeln('   compression_method = ',rec.compression_method);
   writeln('   last_mod_file_time = ',rec.last_mod_file_time);
   writeln('   last_mod_file_date = ',rec.last_mod_file_date);
   writeln('   crc32 = ',rec.crc32);
   writeln('   compressed_size = ',rec.compressed_size);
   writeln('   uncompressed_size = ',rec.uncompressed_size);
   writeln('   disk_number_start = ',rec.disk_number_start);
   writeln('   internal_file_attributes = ',rec.internal_file_attributes);
   writeln('   external_file_attributes = ',rec.external_file_attributes);
   writeln('   relative_offset_local_header = ',rec.relative_offset_local_header);
***********)

end;


(* ---------------------------------------------------------- *)
procedure process_end_central_dir;
var
   n:             word;
   rec:           end_central_dir_record;
   comment:       string;

begin
   n := dos_read(zipfd,rec,sizeof(rec));
   get_string(rec.zipfile_comment_length,comment);

(*******
   writeln;
   writeln('end central dir');
   writeln('   zipfile comment = ',comment);
   writeln('   number_this_disk = ',rec.number_this_disk);
   writeln('   number_disk_with_start_central_directory = ',rec.number_disk_with_start_central_directory);
   writeln('   total_entries_central_dir_on_this_disk = ',rec.total_entries_central_dir_on_this_disk);
   writeln('   total_entries_central_dir = ',rec.total_entries_central_dir);
   writeln('   size_central_directory = ',rec.size_central_directory);
   writeln('   offset_start_central_directory = ',rec.offset_start_central_directory);
********)

end;

(* ---------------------------------------------------------- *)
procedure process_headers;
var
   sig:  longint;
   fail: integer;

begin
   fail := 0;

   while true do
   begin

      if dos_read(zipfd,sig,sizeof(sig)) <> sizeof(sig) then
         exit
      else

      if sig = local_file_header_signature then
         process_local_file_header
      else

      if sig = central_file_header_signature then
         process_central_file_header
      else

      if sig = end_central_dir_signature then
      begin
         process_end_central_dir;
         exit;
      end
      else

      begin
         inc(fail);
         if fail > 100 then
         begin
            writeln('Invalid Zipfile Header!');
            exit;
         end;
      end;
   end;
end;

(* ---------------------------------------------------------- *)
procedure list_zip(name: dos_filename);
begin
   zipfd := dos_open(name,open_read);
   if zipfd = dos_error then
   begin
      writeln('Can''t open: ',name);
      exit;
   end;
   writeln;
   if (pos('?',zipfn)+pos('*',zipfn)) > 0 then
   begin
      writeln('Zipfile: '+name);
      writeln;
   end;
   writeln('  Size    Method   Zipped     Date      Time     Type     File Name');
   if (asciigraphics in urec.config) then
   writeln('컴컴컴컴 컴컴컴컴 컴컴컴컴  컴컴컴컴  컴컴컴컴  컴컴컴  컴컴컴컴컴컴�')
   else
   writeln('-------- -------- --------  --------  --------  ------  -------------');
   process_headers;
   dos_close(zipfd);
end;


(* ---------------------------------------------------------- *)

procedure arcview (fname:lstr);
var f:file of byte;
    b:byte;
    sg:boolean;
    size:longint;
    n:integer;

function getsize:longint;
var x:longint;
    b:array [1..4] of byte absolute x;
    cnt:integer;
begin
 for cnt:=1 to 4 do read (f,b[cnt]);
 getsize:=x
end;

begin
 assign (f,fname);
 reset (f);
 iocode:=ioresult;
 if iocode<>0 then begin
  fileerror ('LISTARCHIVE',fname);
  exit;
 end;
 if (filesize(f)<32) then begin
  writeln (^M'That file isn''t an archive!');
  close (f);
  exit;
 end;
 writeln ('Filename.Ext    Size');
 if (asciigraphics in urec.config) then
 writeln ('컴컴컴컴컴컴    컴컴') else
 writeln ('------------    ----');
 repeat
  read (f,b);
  if b<>26 then begin
   writeln (^M'That file isn''t an archive!');
   close (f);
   exit
  end;
  read (f,b);
  if b=0 then begin
   close (f);
   exit
  end;
  sg:=false;
  for n:=1 to 13 do begin
   read (f,b);
   if b=0 then sg:=true;
   if sg then b:=32;
   write (chr(b))
  end;
  size:=getsize;
  for n:=1 to 6 do read (f,b);
  writeln ('   ',getsize);
  seek (f,filepos(f)+size)
 until break or hungupon;
end;

procedure pakview (filename:lstr);
var f:file of byte;
begin
 if not exist (pak) then begin
  writeln (^M'Error: '+pak+' not found. Notify Sysop.'^M);
  exit;
 end;
 exec (commandcom,'/C '+pak+' v '+filename+' >PAK.LST');
 printfile ('PAK.LST')
end;

procedure zipview (fn:lstr);
var f:file of byte;
    dirinfo:searchrec;
    dir,nam,ext:dos_filename;
begin
 assign (f,fn);
 reset (f);
 iocode:=ioresult;
 if iocode<>0 then begin
  fileerror ('LISTARCHIVE',fn);
  exit;
 end;
 if (filesize(f)<32) then begin
  writeln (^M'That file isn''t an archive!');
  close (f);
  exit;
 end;
 close (f);
 zipfn:=fn;
 if pos('.',zipfn) = 0 then zipfn:=zipfn+'.Zip';
 fsplit(zipfn,dir,nam,ext);
 findfirst(zipfn,$21,dirinfo);
 while (doserror=0) do
 begin
  list_zip (dir+dirinfo.name);
  findnext (dirinfo);
 end;
end;

begin
end.
