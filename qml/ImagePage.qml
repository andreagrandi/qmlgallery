/*
 * Copyright (C) 2012 Andrea Bernabei <and.bernabei@gmail.com>
 *
 * You may use this file under the terms of the BSD license as follows:
 *
 * "Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:
 *   * Redistributions of source code must retain the above copyright
 *     notice, this list of conditions and the following disclaimer.
 *   * Redistributions in binary form must reproduce the above copyright
 *     notice, this list of conditions and the following disclaimer in
 *     the documentation and/or other materials provided with the
 *     distribution.
 *   * Neither the name of Nemo Mobile nor the names of its contributors
 *     may be used to endorse or promote products derived from this
 *     software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE."
 */

import QtQuick 1.1
import com.nokia.meego 1.0
import QtMobility.gallery 1.1

Page{
    id: imagepage
    anchors.fill:parent

    tools: imgTools

    property alias imageId: imageview.currentIndex
    property alias galleryModel: imageview.model

    ListView{
        id: imageview
        anchors.fill:parent
        clip: true

        orientation: ListView.Horizontal
        highlightRangeMode: ListView.StrictlyEnforceRange

        //Set duration to 0 to skip listview animation when passing from grid to listview
        highlightMoveDuration: 1
        highlightResizeDuration: 1

        cacheBuffer:2*width

        snapMode: ListView.SnapOneItem

        delegate: Item{
            id: imgContainer

            width: imageview.width
            height: imageview.height

            PinchArea{
                id: pinchImg
                anchors.fill: imgContainer

                //Disable the pincharea if the listview is scrolling, to avoid problems
                enabled: !imageview.moving
                pinch.target: img
                pinch.maximumScale: 5
                pinch.dragAxis: Pinch.NoDrag

                property real lastContentX: 0
                property real lastContentY: 0
                property real lastScaleX: 1
                property real lastScaleY: 1
                property real deltaX: 0
                property real deltaY: 0
                property bool initializedX: false
                property bool initializedY: false
                property bool isZoomingOut: false


                function updateContentX(){

                    //Only calculate the correct ContentX if the image is wider than the screen, otherwise keep it centered (contentX = 0 in the else branch)
                    if (rect.width == imageview.width){

                        //Anchors the image to the left
                        if (flickImg.contentX < 0){
                            deltaX = 0.0
                            lastContentX = 0.0
                            flickImg.contentX = 0.0
                        }
                        else {
                            //if the right end of the image is inside the screen area, lock it to the right and zoom out using right edge as an anchor
                            if ((flickImg.contentWidth - flickImg.contentX < parent.width) && isZoomingOut){

                                //align to the right
                                flickImg.contentX -= parent.width - (flickImg.contentWidth - flickImg.contentX)

                                //Algo: set variable as if a new pinch starting from right edge were triggered
                                lastContentX = flickImg.contentX
                                deltaX = flickImg.contentX + parent.width
                                lastScaleX = img.scale
                            }

                            flickImg.contentX = (lastContentX + deltaX * ((img.scale / lastScaleX) - 1.0 ))
                        }
                    }
                    else{
                        flickImg.contentX = 0
                    }
                }

                function updateContentY(){

                    //Only calculate the correct ContentY if the image is taller than the screen, otherwise keep it centered (contentY = 0 in the else branch)
                    if (rect.height == imageview.height){

                        //Anchors the image to the top when zooming out
                        if (flickImg.contentY < 0){
                            deltaY = 0.0
                            lastContentY = 0.0
                            flickImg.contentY = 0.0
                        }
                        else {
                            //if the bottom end of the image is inside the screen area, lock it to the bottom and zoom out using bottom edge as an anchor
                            if ((flickImg.contentHeight - flickImg.contentY < parent.height) && isZoomingOut){

                                //align to the bottom
                                flickImg.contentY -= parent.height - (flickImg.contentHeight - flickImg.contentY)

                                //Algo: set variable as if a new pinch starting from bottom edge were triggered
                                lastContentY = flickImg.contentY
                                deltaY = flickImg.contentY + parent.height
                                lastScaleY = img.scale
                            }
                            flickImg.contentY = (lastContentY + deltaY * ((img.scale / lastScaleY) - 1.0 ))
                        }
                    }
                    else{
                        flickImg.contentY = 0
                    }
                }


                onPinchUpdated:{
                    //Am I zooming in or out?
                    if (pinch.scale > pinch.previousScale) isZoomingOut = false
                    else isZoomingOut = true

                    //Get updated "zoom center point" values when the image is completely zoomed out
                    if(img.scale == 1){
                        //This is so that everytime you zoom out, the new zoom is started with updated values
                        initializedX = false
                        initializedY = false
                    }

                    //i.e. everytime the image is wider than the screen, it should actually be
                    // img.width == imageview.width, but this condition is rarely met because of numeric error
                    if (rect.width == imageview.width)
                    {
                        if (!initializedX )
                        {
                            //If it has not already been set by the "if (height == imageview.height)" branch, set the scale here
                            lastScaleX = img.scale

                            lastContentX = flickImg.contentX
                            deltaX = flickImg.contentX + pinch.center.x
                            initializedX = true;
                        }

                    }

                    if (rect.height == imageview.height)
                    {
                        if (!initializedY)
                        {
                            //If it has not already been set by the "if (width == imageview.width)", set the scale here
                            lastScaleY = img.scale

                            lastContentY = flickImg.contentY
                            deltaY = flickImg.contentY + pinch.center.y
                            initializedY = true;
                        }

                    }

                    // updateContentX and updateContentY are called after the scale on the target item updates bindings
                }

                onPinchFinished: {
                    lastContentX = flickImg.contentX
                    lastContentY = flickImg.contentY

                    initializedX = false
                    initializedY = false
                }

            }

            Item{
                id: rect
                anchors.centerIn:parent

                width:  Math.min(img.width*img.scale, parent.width)
                height: Math.min(img.height*img.scale, parent.height)

                Flickable{
                    id: flickImg

                    anchors.fill:rect
                    transformOrigin: Item.TopLeft

                    contentWidth: img.width * img.scale
                    contentHeight: img.height * img.scale

                    onContentWidthChanged: { pinchImg.updateContentX(); pinchImg.updateContentY(); }
                    onContentHeightChanged: { pinchImg.updateContentX(); pinchImg.updateContentY(); }

                    Image{
                        id: img

                        //For Harmattan/Nemo ( THIS PART HAS TO BE FIXED , THE IMAGE IS NOT SCALED TO FILL THE SCREEN ATM)
                        property real imgRatio: galleryModel.get(index).width / galleryModel.get(index).height
                        property bool fitsVertically: imgRatio < (imgContainer.width / imgContainer.height)
                        width: (fitsVertically) ? (imageview.height * imgRatio) : imageview.width
                        height: (fitsVertically) ? (imageview.height) : (imageview.width / imgRatio)

                        //For Simulator:
                        //width: 480
                        //fillMode: Image.PreserveAspectFit

                        transformOrigin: Item.TopLeft
                        asynchronous: true
                        source: url
                        sourceSize.width: 2000
                        sourceSize.height: 2000

                        //Disable ListView scrolling if you're zooming
                        onScaleChanged: {
                            if (scale != 1 && imageview.interactive == true) imageview.interactive = false
                            else if (scale == 1 && imageview.interactive == false) imageview.interactive = true
                        }

                        MouseArea {
                            anchors.fill: parent

                            Timer {
                                id: doubleClickTimer
                                interval: 350
                            }

                            // onDoubleClicked seems broken on-device with all of the flickable/pincharea here
                            onClicked: {
                                if (doubleClickTimer.running) {
                                    img.scale = 1
                                    flickImg.contentX = flickImg.contentY = 0
                                }
                                else
                                    doubleClickTimer.start()
                            }
                        }
                    }

                }

            }

        }


    }

    ToolBarLayout {
            id: imgTools
            ToolIcon {
                platformIconId: "toolbar-back"
                anchors.left: (parent === undefined) ? undefined : parent.left
                onClicked: appWindow.pageStack.pop()
            }
    }
}
