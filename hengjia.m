%bar2.m
clc,clear;
tic;
x = [0 500 500 0];   % 节点x轴向方向坐标
y = [0 0 500 500];   % 节点y轴方向坐标
A = 300; E = 2.1E005;   % 定义截面面积和弹性模量
% 单元信息=[编号 节点1编号 节点2编号 截面面积 弹性模量]
ele = [1 1 2 A E; 2 2 3 A E; 3 3 4 A E; 4 1 3 A E; 5 2 4 A E];
Load = [3 0 -1000];   % 载荷信息=[节点编号 x方向力 y方向力]
Constr = [1 0 0; 4 0 0];   % 约束=[节点编号 x方向约束 y方向约束]
[U, Strain, Stress, AxialForce] = Truss2DFEA(x, y, ele, Load, Constr, 1000);
toc;



%Truss2DFEA.m
%************************************************************************************
%*************** 桁架结构有限元建模与静态求解程序  王国镔 左文杰 吉林大学 ***************
%******************* 调用方式：直接运行外部的桁架结构程序，如：Bar26 *******************
%************************************************************************************
function [U, Strain, Stress, AxialForce] = Truss2DFEA(x, y, ele, Load, Constr, Scale)
    Dofs = 2 * size(x, 2);   % 总自由度数
    EleCount = size(ele, 1);   % 单元总数
    K = zeros(Dofs, Dofs);   % 初始化总体刚度矩阵
    F = zeros(Dofs, 1);   % 初始化总体载荷列阵
    U = zeros(Dofs, 1);   % 初始化总体位移列阵
    BarLength = BarsLength(x, y, ele);
    %figure('Name','Undeformed Truss');
    %RenderTruss(ele, Load, Constr, x, y, U, 1, '-k', 1);   % 绘制桁架
    figure('Name','Undeformed and Deformed Truss');
    RenderTruss(ele, Load, Constr, x, y, U, 0.5, '-k', 1);   % 先绘制未变形桁架
    hold on;
    % 遍历所有单元，将各单元刚度阵分块组装到总体刚度阵
    for iEle = 1:EleCount
        % 该单元的两个节点的编号
        n1 = ele(iEle, 2); n2 = ele(iEle, 3);
        % 计算坐标变换矩阵
        R = CoordTransform([x(n1) x(n2)],[y(n1) y(n2)], BarLength(iEle));
        % 计算单元刚度矩阵
        ke = BarElementKe(ele(iEle, 4), ele(iEle, 5), R, BarLength(iEle));
        % 将各单元刚度分块组装到总刚度相应位置
        K(2*n1-1:2*n1, 2*n1-1:2*n1) = K(2*n1-1:2*n1, 2*n1-1:2*n1) + ke(1:2, 1:2);
        K(2*n1-1:2*n1, 2*n2-1:2*n2) = K(2*n1-1:2*n1, 2*n2-1:2*n2) + ke(1:2, 3:4);
        K(2*n2-1:2*n2, 2*n1-1:2*n1) = K(2*n2-1:2*n2, 2*n1-1:2*n1) + ke(3:4, 1:2);
        K(2*n2-1:2*n2, 2*n2-1:2*n2) = K(2*n2-1:2*n2, 2*n2-1:2*n2) + ke(3:4, 3:4);
    end
    % 形成载荷列阵
    for i = 1:size(Load, 1)
        F(2 * Load(i) - 1, 1) = Load(i, 2);
        F(2 * Load(i), 1) = Load(i, 3);
    end
    % 施加约束——乘大数法
    for i = 1:size(Constr, 1)
        PositionOfDoFs = 2 * Constr(i, 1);
        temp1 = K(PositionOfDoFs - 1, PositionOfDoFs - 1);
        temp2 = K(PositionOfDoFs, PositionOfDoFs);
        K(PositionOfDoFs - 1, PositionOfDoFs - 1) = 1e10 * temp1;
        K(PositionOfDoFs, PositionOfDoFs) = 1e10 * temp2;
        F(PositionOfDoFs - 1) = 1e10 * Constr(i, 2) * temp1;
        F(PositionOfDoFs) = 1e10 * Constr(i, 3) * temp2;
    end
    
    U = pinv(K) * F;     % 计算全局坐标系下位移
    
    % 计算杆单元的应变、应力、轴力
    for i = 1:EleCount
        n1 = ele(i, 2); n2 = ele(i, 3);
        R = CoordTransform([x(n1) x(n2)], [y(n1) y(n2)], BarLength(i));
        localU = R * [U(2*n1-1:2*n1, 1); U(2*n2-1:2*n2, 1)];  % 计算杆局部坐标系下的位移
        Strain(1, i) = [-1/BarLength(i) 1/BarLength(i)] * localU;   % 应变
        Stress(1, i) = ele(i, 5) * Strain(1, i);   % 应力
        AxialForce(1, i) = ele(i, 4) * Stress(1, i);  % 轴力
    end
    % 保存位移，应力与轴力到文本文件
    fp = fopen('Result.txt','a');
    str = [char(13, 10)','U',' ',num2str(U'),...
           char(13, 10)','Stress',' ',num2str(Stress),...
           char(13, 10)','AxialForce',' ',num2str(AxialForce)];
    fprintf(fp, str);
    fclose(fp);
    RenderTruss(ele, Load, Constr, x, y, U, 1, '-.b', Scale);  % 绘制变形后桁架
end   % 主程序结束

% 计算单元刚度矩阵函数
function [Ke] = BarElementKe(A, E, R, BarLength)
    ke = A * E / BarLength * [1 -1;-1 1];
    Ke = R' * ke * R;
end

% 计算杆长函数
function [BarLength] = BarsLength(x, y, ele)
    BarLength = zeros(size(ele, 1), 1);
    for iEle = 1 : size(ele, 1)
        BarLength(iEle, 1) = ((x(ele(iEle, 3)) - x(ele(iEle, 2)))^2 + (y(ele(iEle, 3)) - y(ele(iEle, 2)))^2)^0.5;
    end
end

% 局部坐标与全局坐标的转换函数
function [R] = CoordTransform(x, y, BarLength)
    l = (x(2) - x(1)) / BarLength;
    m = (y(2) - y(1)) / BarLength;
    R = [l m 0 0;0 0 l m];
end

%绘制桁架函数，Scale为变形缩放系数(以下为绘制图像部分）
function RenderTruss(ele, Load, Constr, x, y, U, LineWidth, LineStyle, Scale)
    CoordScale = [max(x) - min(x), max(y) - min(y)];
    k = 1;
%计算变形后坐标
    for i = 1: length(x)
        if Constr(k, 1) == i     %--约束节点坐标不变
            k = k + 1;
        else       %--非约束节点坐标加上缩放后的位移
            x(i) = x(i) + Scale * U(2 * i - 1, 1);
            y(i) = y(i) + Scale * U(2 * i, 1);
        end
    end
%绘制杆件
    for i = 1: length(ele(:, 1))
        plot([x(ele(i, 2)), x(ele(i, 3))], [y(ele(i, 2)), y(ele(i, 3))],...
             LineStyle, 'LineWidth' ,LineWidth * ele(i, 4) / max(ele(:, 4)));
        hold on
    end
%绘制节点
    for i = 1: length(x)
        x1 = x(i); y1=y(i);
        scatter(x1, y1, 15, 'k', 'filled') 
    end

%绘制载荷
    maxLoad = abs(Load(1, 2)); %寻找绝对值最大的载荷
    for i = 1: length(Load(:, 1))
        if(maxLoad < abs(Load(i, 3))) 
            maxLoad = abs(Load(i, 3))
        end
    end
    for i = 1: length(Load(:, 1))%绘制载荷箭头
        quiver(x(Load(i, 1)), y(Load(i, 1)), Load(i, 2) / max(maxLoad), Load(i, 3) / max(maxLoad),...
        'LineWidth', 1, 'color', 'r', 'AutoScaleFactor', 0.15 * (CoordScale(1) + CoordScale(2)),...
        'MaxHeadSize', 0.01 * (CoordScale(1) + CoordScale(2)));
    end
%绘制约束--选用结构最大的坐标尺寸作为基准来绘制约束
    for i = 1: length(Constr(:, 1))
        plot([x(Constr(i, 1)) x(Constr(i, 1))-0.02*max(CoordScale) x(Constr(i, 1))+...
            0.02*max(CoordScale) x(Constr(i, 1))], [y(Constr(i, 1)) y(Constr(i, 1))-...
            0.02*max(CoordScale) y(Constr(i, 1))-0.02*max(CoordScale) y(Constr(i, 1))],...
            'LineWidth', 0.8, 'color', 'r');
    end
%绘制坐标轴
    axis equal
    axis([min(x)-0.1*CoordScale(1), max(x)+0.1*CoordScale(1), min(y)-...
        0.1*CoordScale(2), max(y)+0.1*CoordScale(2)]) %限定图像的显示范围
    hold off
end