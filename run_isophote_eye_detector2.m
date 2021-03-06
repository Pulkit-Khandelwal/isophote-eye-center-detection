function [ecx,ecy,k,c,D,acc,sacc,ind,Lx,Ly,Lxx,Lxy,Lyy]=run_isophote_eye_detector2(img,imgeye,recteye,gsigma)
    % RUN_ISOPHOTE_EYE_DETECTOR determines the most likely eye-center
    %   location in the image.
    %
    % This implementation allows to speficy an eye-detection rectangle
    % (i.e., a bounding box around the eye region) within the given image.
    %
    % @author Boris Schauerte
    % @email  boris.schauerte@eyezag.com
    % @date   2011
    %
    % Copyright (C) 2011  Boris Schauerte
    % 
    % This program is free software: you can redistribute it and/or modify
    % it under the terms of the GNU General Public License as published by
    % the Free Software Foundation, either version 3 of the License, or
    % (at your option) any later version.
    %
    % This program is distributed in the hope that it will be useful,
    % but WITHOUT ANY WARRANTY; without even the implied warranty of
    % MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    % GNU General Public License for more details.
    %
    % You should have received a copy of the GNU General Public License
    % along with this program.  If not, see <http://www.gnu.org/licenses/>.
    
    if nargin < 2
        gsigma = 1;
    end
    
    % run isophote eye detector
    %[k,c,D,R,ind,Lx,Ly,Lxx,Lxy,Lyy,hx,hy,hxx,hxy,hyy]=isophote_calculation(imgeye,gsigma); %simple version that ignores the invalid votes at the image edges, which can cause problems
    %[k,c,D,R,ind,Lx,Ly,Lxx,Lxy,Lyy,hx,hy,hxx,hxy,hyy]=isophote_calculation2(imgeye,gsigma,'same'); %simple version that ignores the invalid votes at the image edges, which can cause problems
    [x,Wx]=isophote_calculation2_get_support(gsigma);
    imgsz=size(img); imgsz=imgsz(1:2);
    if recteye(1) - Wx >= 1 && recteye(2) - Wx >= 1 && recteye(3) + Wx <= imgsz(2) && recteye(4) + Wx <= imgsz(1) % just use valid pixels (makes it necessary to consider a bigger eye rectangle)
        vimgeye=img((recteye(2) - Wx):(recteye(4) + Wx),(recteye(1) - Wx):(recteye(3) + Wx));
        [k,c,D,R,ind,Lx,Ly,Lxx,Lxy,Lyy,hx,hy,hxx,hxy,hyy]=isophote_calculation2(vimgeye,gsigma,'valid');
        assert(isequal(size(k),size(imgeye)));
    else
        %[k,c,D,R,ind,Lx,Ly,Lxx,Lxy,Lyy,hx,hy,hxx,hxy,hyy]=isophote_calculation2(imgeye,gsigma,'same'); % also consider invalid values (i.e. at the border of the convolution the derivatives will be wrong/invalid)
        [k,c,D,R,ind,Lx,Ly,Lxx,Lxy,Lyy,hx,hy,hxx,hxy,hyy]=isophote_calculation2(imgeye,gsigma,'pad'); % also consider invalid values (i.e. at the border of the convolution the derivatives will be wrong/invalid)
    end
    
    % accumulator (simple implementation)
    imgeyesz=size(imgeye); imgeyesz=imgeyesz(1:2);
    acc = zeros(imgeyesz);
    for x=1:imgeyesz(2)
        for y=1:imgeyesz(1)
            if not(isnan(c(y,x))) && not(isinf(c(y,x))) && k(y,x) < 0 %&& R(y,x) < 0.15*norm(imgeyesz)%0.125*norm(imgeyesz)
                %if not(isnan(c(y,x))) && not(isinf(c(y,x))) && k(y,x) < 0 && R(y,x) < 0.15*norm(imgeyesz) && R(y,x) > 2 % %0.125*norm(imgeyesz) && R(y,x) > 2 %
                %   ignore votes with positive curvature, because this is
                %   specifically interesting to detect the iris (because "it can
                %   be assumed that the sclera is brighter than the cornea and the
                %   iris)
                
                % better
                indx = ind(y,x,1);
                indy = ind(y,x,2);
                if indx < 1 || indy < 1 || indx > imgeyesz(2) || indy > imgeyesz(1)
                    break
                end
                
                acc(indy,indx) = acc(indy,indx) + c(y,x);
                %acc(indy,indx) = acc(indy,indx) + (c(y,x))^(1/2);%(2/3);
            end
        end
    end
    
    % post-process
    h = fspecial('gaussian',11,3);
    %h = fspecial('gaussian',7,3);
    %h = fspecial('gaussian',9,2.5);
    sacc = conv2(acc,h,'same');
    %sacc = conv2pad(acc,h);
    
    % select MIC (Maximum Isocenter)
    [tmp,i] = max(sacc);
    [~,j] = max(tmp);
    ymic = i(j);
    xmic = j;
    
    % cluster -> gradient ascend to other true center (e.g. use mean shift)
    % ...
    
    % verify eye center location (e.g. with SIFT)
    % ...
    
    % set output eye center x and y coordinates
    ecx = xmic;
    ecy = ymic;