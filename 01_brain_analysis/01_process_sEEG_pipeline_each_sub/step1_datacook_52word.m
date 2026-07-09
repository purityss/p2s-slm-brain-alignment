clear all
close all
%% load
Ada1=pop_biosig( 'adaptation1.edf');
Ada2=pop_biosig( 'adaptation2.edf');
Ada3=pop_biosig( 'adaptation3.edf');
Ada4=pop_biosig( 'adaptation4.edf');
dataCell = {Ada1.data, Ada2.data, Ada3.data, Ada4.data};
mergedData = [];
for i = 1:4
    mergedData = [mergedData, dataCell{i}];
end
mergedStruct = Ada1; % Use the first structure as the base
mergedStruct.data = mergedData; % Replace the data field with the merged data
EEG1 = mergedStruct;
%% delete bad electrodes
EEG2 = pop_chanevent( EEG1, [ ],'edge','leading','oper','X > 10000' );   
%% plot trigger channel to check
chan_trig = EEG2.nbchan; %127;
figure;
plot( EEG2.data(chan_trig,:)); 
% close
%% read trigger   Read the time periods when the trigger is received
%posEEG = EEG2;
posEEG = pop_chanevent(  EEG2, [ EEG2.nbchan],'edge','leading','oper','X > 2000' );
%% delete some wrong
   for i = 2:  length(posEEG.event)
     delLan=posEEG.event(i).latency-posEEG.event(i-1).latency;
        if delLan < 200
            posEEG.event(i).type = num2str(999);
            posEEG.urevent(i).type = num2str(999);
        else
           
    end
   end
   
j=0;
  for i = 1:length(posEEG.event)
      if str2num(posEEG.event(i).type)==1
            j=j+1;
      else
      end
  end
 disp('num_event = ');
 num_event = j
 %% filter 0-20 ERP; 20-250 EFR
 [posEEG0, com, b] = pop_eegfiltnew( posEEG, 0.5, 200);  
%  [posEEG0, com, b] = pop_eegfiltnew( posEEG,60,150);   
   for i=1:size(posEEG0.data,1)
    posEEG0.data(i,:)=abs(hilbert(posEEG0.data(i,:)));
   end
   
 %% load logfile
load logfile_newword   % Stimulus type
%% type = = condition
j=1;
  for i = 1:length(posEEG.event)
      if str2num(posEEG.event(i).type)==1
            posEEG0.event(i).type = num2str(logfile(1,j));
            posEEG0.urevent(i).type = num2str(logfile(1,j));
            j=j+1;
      else
      end
  end
 
   %% epoch  
  a = -0.2;
  b = 1.2;
  [posEEG1, indices] = pop_epoch( posEEG0, {'1'}, [a b]); 
  [posEEG2, indices] = pop_epoch( posEEG0, {'2'}, [a b]);
  [posEEG3, indices] = pop_epoch( posEEG0, {'3'}, [a b]);
  [posEEG4, indices] = pop_epoch( posEEG0, {'4'}, [a b]); 
  [posEEG5, indices] = pop_epoch( posEEG0, {'5'}, [a b]);
  [posEEG6, indices] = pop_epoch( posEEG0, {'6'}, [a b]);
  [posEEG7, indices] = pop_epoch( posEEG0, {'7'}, [a b]); 
  [posEEG8, indices] = pop_epoch( posEEG0, {'8'}, [a b]);
  [posEEG9, indices] = pop_epoch( posEEG0, {'9'}, [a b]);
  [posEEG10, indices] = pop_epoch( posEEG0, {'10'}, [a b]); 
  [posEEG11, indices] = pop_epoch( posEEG0, {'11'}, [a b]);
  [posEEG12, indices] = pop_epoch( posEEG0, {'12'}, [a b]);
  [posEEG13, indices] = pop_epoch( posEEG0, {'13'}, [a b]); 
  [posEEG14, indices] = pop_epoch( posEEG0, {'14'}, [a b]);
  [posEEG15, indices] = pop_epoch( posEEG0, {'15'}, [a b]);
  [posEEG16, indices] = pop_epoch( posEEG0, {'16'}, [a b]); 
  [posEEG17, indices] = pop_epoch( posEEG0, {'17'}, [a b]);
  [posEEG18, indices] = pop_epoch( posEEG0, {'18'}, [a b]);
  [posEEG19, indices] = pop_epoch( posEEG0, {'19'}, [a b]); 
  [posEEG20, indices] = pop_epoch( posEEG0, {'20'}, [a b]);
  [posEEG21, indices] = pop_epoch( posEEG0, {'21'}, [a b]);
  [posEEG22, indices] = pop_epoch( posEEG0, {'22'}, [a b]); 
  [posEEG23, indices] = pop_epoch( posEEG0, {'23'}, [a b]);
  [posEEG24, indices] = pop_epoch( posEEG0, {'24'}, [a b]);
  [posEEG25, indices] = pop_epoch( posEEG0, {'25'}, [a b]); 
  [posEEG26, indices] = pop_epoch( posEEG0, {'26'}, [a b]);
  [posEEG27, indices] = pop_epoch( posEEG0, {'27'}, [a b]);
  [posEEG28, indices] = pop_epoch( posEEG0, {'28'}, [a b]); 
  [posEEG29, indices] = pop_epoch( posEEG0, {'29'}, [a b]);
  [posEEG30, indices] = pop_epoch( posEEG0, {'30'}, [a b]);
  [posEEG31, indices] = pop_epoch( posEEG0, {'31'}, [a b]); 
  [posEEG32, indices] = pop_epoch( posEEG0, {'32'}, [a b]);
  [posEEG33, indices] = pop_epoch( posEEG0, {'33'}, [a b]);
  [posEEG34, indices] = pop_epoch( posEEG0, {'34'}, [a b]); 
  [posEEG35, indices] = pop_epoch( posEEG0, {'35'}, [a b]);
  [posEEG36, indices] = pop_epoch( posEEG0, {'36'}, [a b]);
  [posEEG37, indices] = pop_epoch( posEEG0, {'37'}, [a b]); 
  [posEEG38, indices] = pop_epoch( posEEG0, {'38'}, [a b]);
  [posEEG39, indices] = pop_epoch( posEEG0, {'39'}, [a b]);
  [posEEG40, indices] = pop_epoch( posEEG0, {'40'}, [a b]); 
  [posEEG41, indices] = pop_epoch( posEEG0, {'41'}, [a b]);
  [posEEG42, indices] = pop_epoch( posEEG0, {'42'}, [a b]);
  [posEEG43, indices] = pop_epoch( posEEG0, {'43'}, [a b]); 
  [posEEG44, indices] = pop_epoch( posEEG0, {'44'}, [a b]);
  [posEEG45, indices] = pop_epoch( posEEG0, {'45'}, [a b]);
  [posEEG46, indices] = pop_epoch( posEEG0, {'46'}, [a b]); 
  [posEEG47, indices] = pop_epoch( posEEG0, {'47'}, [a b]);
  [posEEG48, indices] = pop_epoch( posEEG0, {'48'}, [a b]);
  [posEEG49, indices] = pop_epoch( posEEG0, {'49'}, [a b]);
  [posEEG50, indices] = pop_epoch( posEEG0, {'50'}, [a b]); 
  [posEEG51, indices] = pop_epoch( posEEG0, {'51'}, [a b]);
  [posEEG52, indices] = pop_epoch( posEEG0, {'52'}, [a b]);
  posEEG1.setname='草莓';
  posEEG2.setname='带鱼';
  posEEG3.setname='蛋糕';
  posEEG4.setname='豆腐';
  posEEG5.setname='海带';
  posEEG6.setname='红薯';
  posEEG7.setname='鸡蛋';
  posEEG8.setname='煎饼';
  posEEG9.setname='荔枝';
  posEEG10.setname='龙虾';
  posEEG11.setname='萝卜';
  posEEG12.setname='绿豆';
  posEEG13.setname='芒果';
  posEEG14.setname='蜜桔';
  posEEG15.setname='面包';
  posEEG16.setname='蘑菇';
  posEEG17.setname='牛肉';
  posEEG18.setname='苹果';
  posEEG19.setname='软糖';
  posEEG20.setname='薯条';
  posEEG21.setname='西瓜';
  posEEG22.setname='香肠';
  posEEG23.setname='洋葱';
  posEEG24.setname='樱桃';
  posEEG25.setname='玉米';
  posEEG26.setname='猪蹄';
  posEEG27.setname='草坪';
  posEEG28.setname='代表';
  posEEG29.setname='弹弓';
  posEEG30.setname='逗号';
  posEEG31.setname='海滩';
  posEEG32.setname='红灯';
  posEEG33.setname='机会';
  posEEG34.setname='肩膀';
  posEEG35.setname='力量';
  posEEG36.setname='笼子';
  posEEG37.setname='螺旋';
  posEEG38.setname='律师';
  posEEG39.setname='盲人';
  posEEG40.setname='密码';
  posEEG41.setname='面具';
  posEEG42.setname='模特';
  posEEG43.setname='牛仔';
  posEEG44.setname='评委';
  posEEG45.setname='软件';
  posEEG46.setname='暑假';
  posEEG47.setname='膝盖';
  posEEG48.setname='乡村';
  posEEG49.setname='阳光';
  posEEG50.setname='英雄';
  posEEG51.setname='浴室';
  posEEG52.setname='珠宝';
  ALLEEG(1)=posEEG1;
  ALLEEG(2)=posEEG2;
  ALLEEG(3)=posEEG3;
  ALLEEG(4)=posEEG4;
  ALLEEG(5)=posEEG5;
  ALLEEG(6)=posEEG6;
  ALLEEG(7)=posEEG7;
  ALLEEG(8)=posEEG8;
  ALLEEG(9)=posEEG9;
  ALLEEG(10)=posEEG10;
  ALLEEG(11)=posEEG11;
  ALLEEG(12)=posEEG12;
  ALLEEG(13)=posEEG13;
  ALLEEG(14)=posEEG14;
  ALLEEG(15)=posEEG15;
  ALLEEG(16)=posEEG16;
  ALLEEG(17)=posEEG17;
  ALLEEG(18)=posEEG18;
  ALLEEG(19)=posEEG19;
  ALLEEG(20)=posEEG20;
  ALLEEG(21)=posEEG21;
  ALLEEG(22)=posEEG22;
  ALLEEG(23)=posEEG23;
  ALLEEG(24)=posEEG24;
  ALLEEG(25)=posEEG25;
  ALLEEG(26)=posEEG26;
  ALLEEG(27)=posEEG27;
  ALLEEG(28)=posEEG28;
  ALLEEG(29)=posEEG29;
  ALLEEG(30)=posEEG30;
  ALLEEG(31)=posEEG31;
  ALLEEG(32)=posEEG32;
  ALLEEG(33)=posEEG33;
  ALLEEG(34)=posEEG34;
  ALLEEG(35)=posEEG35;
  ALLEEG(36)=posEEG36;
  ALLEEG(37)=posEEG37;
  ALLEEG(38)=posEEG38;
  ALLEEG(39)=posEEG39;
  ALLEEG(40)=posEEG40;
  ALLEEG(41)=posEEG41;
  ALLEEG(42)=posEEG42;
  ALLEEG(43)=posEEG43;
  ALLEEG(44)=posEEG44;
  ALLEEG(45)=posEEG45;
  ALLEEG(46)=posEEG46;
  ALLEEG(47)=posEEG47;
  ALLEEG(48)=posEEG48;
  ALLEEG(49)=posEEG49;
  ALLEEG(50)=posEEG50;
  ALLEEG(51)=posEEG51;
  ALLEEG(52)=posEEG52;