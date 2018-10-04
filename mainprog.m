% Nama: Fathul Asrar Alfansuri
% NIM : 10113007

function mainprog
%% Pra-Proses
clc
clear all
close all

%% Inisialisasi data
filename = 'geraham';
y_value = 50;
z_value = 1;
c = 70;
n_gambar = 1200;
sudut_pengambilan = 100;
jeda = n_gambar/sudut_pengambilan;
resolusi = 150;
jeda = false;
henti = false;

%% Set folder
% Ganti %user% menjadi user anda
[currentFolder b c] = fileparts(which('mainprog.m'));
clear b c;

%% Bangun figure
w = 768;
h = 768;
fig_handle = figure('position',[100 0 w h]);
static = uicontrol('style','text','position',[0.05*w 0.65*h 0.35*h 150],...
                   'string','Simulasi CT Scan',...
                   'fontsize',40);
inp_objek = uicontrol('style','popup',...
                     'string','tulang|geraham|gipal',...
                     'position',[0.05*w 0.45*h+50 0.35*h 50],...
                     'fontsize',20,...
                     'callback',@call_change_obj);
axe1_handle = axes('units','pixels',...
                   'parent',fig_handle,...
                   'position',[0.05*w 0.05*h 0.35*h 0.35*h]);
axe2_handle = axes('units','pixels',...
                   'parent',fig_handle,...
                   'position',[0.55*w 0.5*h 0.35*h 0.35*h]);
axe3_handle = axes('units','pixels',...
                   'parent',fig_handle,...
                   'position',[0.55*w 0.05*h 0.35*h 0.35*h]);
inp_slider_rotate = uicontrol('style','slider',...
                              'position',[0.55*w 0.45*h 0.35*h 20],...
                              'Min',1,'Max',sudut_pengambilan,'value',1);
addlistener(inp_slider_rotate,'ContinuousValueChange',@(hObj, event) call_rotate(hObj,event));
inp_slider_y_value = uicontrol('style','slider',...
                               'position',[0.9*w 0.5*h 20 0.35*h],...
                               'Min',1,'Max',150,'value',100);
addlistener(inp_slider_y_value,'ContinuousValueChange',@(hObj, event) call_change_y(hObj,event));

btn_reconstruct = uicontrol('style','pushbutton',...
                            'position',[0.05*w 0.45*h 0.35*w 50],...
                            'string','Rekonstruksi!',...
                            'fontsize',20,...
                            'callback',@call_reconstruct);
btn_pause = uicontrol('style','pushbutton',...
                            'position',[0.05*w 0.45*h 0.17*w 50],...
                            'string','jeda',...
                            'fontsize',20,...
                            'visible','off',...
                            'callback',@call_pause);
btn_stop = uicontrol('style','pushbutton',...
                            'position',[0.23*w 0.45*h 0.17*w 50],...
                            'string','henti',...
                            'fontsize',20,...
                            'visible','off',...
                            'callback',@call_stop);

set_gambar = ambil_gambar('tulang',1200,100);
update_axe2;
update_axe1;

%================================================
function update_axe1
    axes(axe1_handle);
    gbr = ambil_sinogram;
    image(gbr*70);
    colormap('gray');
    title('Sinogram');
end
function update_axe2
    set(inp_slider_rotate,'max',sudut_pengambilan);
    set(inp_slider_rotate,'value',z_value);
    axes(axe2_handle);
    gbr = set_gambar(:,:,z_value);
    gbr(y_value,:) = 1;
    image(gbr*70);
    colormap('gray');
    title('Gambar Objek');
end
function call_rotate(hObj,event)
    data = get(hObj,'value');
    z_value = floor(data);
    update_axe2;
end
function call_change_y(hObj,event)
    data = get(hObj,'value');
    y_value = 151-floor(data);
    update_axe2;
    update_axe1;
end
function call_change_obj(hObj,event)
    a = get(hObj,'value');
    switch a
        case 1
            tex = 'tulang';
            n_gambar = 1200;
            sudut_pengambilan = 100;
        case 2
            tex = 'geraham';
            n_gambar = 1200;
            sudut_pengambilan = 100;
        case 5
            tex = 'kepiting';
            n_gambar = 450;
            sudut_pengambilan = 90;
        case 3
            tex = 'gipal';
            n_gambar = 300;
            sudut_pengambilan = 100;
        case 4
            tex = 'otak';
            n_gambar = 35;
            sudut_pengambilan = 35;
            z_value = 1;
    end
    set_gambar = ambil_gambar(tex,n_gambar,sudut_pengambilan);
    update_axe2;
    update_axe1;
end
function call_reconstruct(hObj,event)
    set(btn_reconstruct,'visible','off');
    set(btn_pause,'visible','on');
    set(btn_stop,'visible','on');
    ART(ambil_sinogram);
end
function call_pause(hObj,event)
    jeda = ~jeda;
end
function call_stop(hObj,event)
    henti = ~henti;
end
function result = ambil_sinogram
    result = squeeze(set_gambar(y_value,:,:))';
end

%% Ambil gambar
function result = ambil_gambar(filename,N,n)
    jeda = N/n;
    j = 1;
    txt = '_';
    for i=0:jeda:N-1
        if i<10
            angka = ['000' int2str(i)];
        elseif i<100
            angka = ['00' int2str(i)];
        elseif i<1000
            angka = ['0' int2str(i)];
        else
            angka = int2str(i);
        end
        txt2 = '.png';

        im = imread([currentFolder '\' filename '\' filename txt angka txt2]);
        if size(size(im)) <3
            result(:,:,j) = double(im);
        else
            result(:,:,j) = double(mean(im,3));
        end
        j = j+1;
    end
    result = result - min(min(min(result)));
    result = result / max(max(max(result)));
    if ~strcmp(filename,'otak')
        result = -result+ 1;
    end
end

function ART(sinogram)
    conv = 0.01;
    sumBeam = sinogram';
    [a2,a1] = size(sinogram);
    sudut_pengambilan = a2;
    sudut = linspace(0,180,sudut_pengambilan);

    %% ART
    f = zeros(1,a1*a1);
    fm = zeros(a1,a1);

    k = a1/2;
    xTOj = @(x) x + a1/2;
    yTOi = @(y) -y + a1/2;
    Rot = @(X,t) [cos(t) -sin(t);sin(t) cos(t)]*X;
%     flast = f;
%     while true
    for ctr=1:sudut_pengambilan
        if jeda
            set(btn_pause,'string','lanjut');
            while jeda
                pause(0.1);
                if henti
                    break;
                end
            end
            set(btn_pause,'string','jeda');
        end
        if henti
            break;
        end
        %% Scan tiap sudut
        t = sudut(ctr);
        teta = t*pi/180;

        %% add
        if ctr==sudut_pengambilan
            a1_1 = a1-1;
        else
            a1_1 = a1;
        end
        %% Fungsi ART
        for j=1:a1_1
            %% Menentukan koefisien beam, Algoritma Wu
            beam = zeros(1,a1*a1);
            %% Menentukan titik2 ujung garis Wu
            r = j-a1/2;
            x1 = r*cos(teta) - k*sin(teta);
            y1 = r*sin(teta) + k*cos(teta);
            x2 = r*cos(teta) + k*sin(teta);
            y2 = r*sin(teta) - k*cos(teta);

            %% Algoritma Wu:
            % Inisialisasi program
            dy = y2-y1;
            dx = x2-x1;
            cy = sign(dy);
            cx = sign(dx);

            % Proses gambar
            if abs(dy)<abs(dx)
                %% Pasangan pixel atas-bawah
                xr1 = round(x1);
                xr2 = round(x2);
                for i=xr1+1:cx:xr2-1
                    yi = y1 + (i-x1)*dy/dx;
                    yf = floor(yi);
                    ye = yi-yf;
                    iPos = yTOi(yf);
                    ibPos = yTOi(yf+1);
                    jPos = xTOj(i);
                    if 1<=iPos && iPos<=a1 && 1<=jPos && jPos<=a1
                        beam((iPos-1)*a1+jPos) = 1-ye;
                    end
                    if 1<=ibPos && ibPos<=a1 && 1<=jPos && jPos<=a1
                        beam((ibPos-1)*a1+jPos) = ye;
                    end
                end
            else
                %% Pasangan pixel kiri-kanan
                yr1 = round(y1);
                yr2 = round(y2);
                for i=yr1+1:cy:yr2-1
                    xi = x1 + (i-y1)*dx/dy;
                    xf = floor(xi);
                    xe = xi-xf;
                    iPos = yTOi(i);
                    jPos = xTOj(xf);
                    jbPos = xTOj(xf+1);
                    if 1<=iPos && iPos<=a1 && 1<=jPos && jPos<=a1
                        beam((iPos-1)*a1+jPos) = 1-xe;
                    end
                    if 1<=iPos && iPos<=a1 && 1<=jbPos && jbPos<=a1
                        beam((iPos-1)*a1+jbPos) = xe;
                    end
                end
            end
            wi = beam;
            dwi = dot(wi,wi);
            if dwi>0
                f = f - (dot(f,wi)-sumBeam(j,ctr))*wi/dwi;
            end
        end

        %% Tampilkan Hasil ART Tiap Sudut
        fm0 = fm;
        fm = reshape(f,a1,a1);
        fm = fm';
        fm = fm/max(max(fm));       % Normalisasi
        axes(axe3_handle);
        image(fm*70);
        colormap('gray')
        msg = sprintf('Iterasi ke: %d\nSudut: %.2f derajat',j+(ctr-1)*a1,t);
        title(msg);

        % Tampilkan Data Melalui Judul
        pause(0.01);
    end
    henti = false;
    jeda = false;
    set(btn_reconstruct,'visible','on');
    set(btn_pause,'visible','off');
    set(btn_stop,'visible','off');
%     flast0 = flast;
%     flast = f;
%     if abs(max(flast-flast0))<conv
%         break;
%     end
%     end
end

end